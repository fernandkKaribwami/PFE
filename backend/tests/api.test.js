const test = require('node:test');
const assert = require('node:assert/strict');
const { execFileSync } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');

const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const request = require('supertest');
const { MongoMemoryServer } = require('mongodb-memory-server');

const { createApp } = require('../app');
const Faculty = require('../models/Faculty');
const Message = require('../models/Message');
const Notification = require('../models/Notification');
const Post = require('../models/Post');
const Report = require('../models/Report');
const Story = require('../models/Story');
const User = require('../models/User');
const {
  backfillEmailVerificationIfDisabled,
} = require('../utils/userMaintenance');

process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-secret';
process.env.MONGOMS_DOWNLOAD_DIR =
  process.env.MONGOMS_DOWNLOAD_DIR ||
  path.join(__dirname, '..', '.cache', 'mongodb-binaries');
process.env.MONGOMS_PREFER_GLOBAL_PATH = 'false';
process.env.MONGOMS_SYSTEM_BINARY_VERSION_CHECK = 'false';
fs.mkdirSync(process.env.MONGOMS_DOWNLOAD_DIR, { recursive: true });

const resolveMongoSystemBinary = () => {
  if (process.env.MONGOMS_SYSTEM_BINARY) {
    return process.env.MONGOMS_SYSTEM_BINARY;
  }

  const fallbackCandidates = [
    'C:\\Program Files\\MongoDB\\Server\\8.2\\bin\\mongod.exe',
    'C:\\Program Files\\MongoDB\\Server\\8.0\\bin\\mongod.exe',
    'C:\\Program Files\\MongoDB\\Server\\7.0\\bin\\mongod.exe',
  ];

  try {
    const locatedBinary = execFileSync('where', ['mongod'], {
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    })
      .split(/\r?\n/)
      .map((entry) => entry.trim())
      .find(Boolean);

    if (locatedBinary) {
      return locatedBinary;
    }
  } catch (error) {
    // Ignore and try default installation locations below.
  }

  return fallbackCandidates.find((candidate) => fs.existsSync(candidate));
};

const mongoSystemBinary = resolveMongoSystemBinary();
if (mongoSystemBinary) {
  process.env.MONGOMS_SYSTEM_BINARY = mongoSystemBinary;
}

const app = createApp();

const signToken = (user) =>
  jwt.sign(
    { user: { id: user._id.toString(), role: user.role } },
    process.env.JWT_SECRET
  );

let mongoServer;

test.before(async () => {
  mongoServer = await MongoMemoryServer.create();
  await mongoose.connect(mongoServer.getUri());
});

test.after(async () => {
  await mongoose.disconnect();
  if (mongoServer) {
    await mongoServer.stop();
  }
});

test.beforeEach(async () => {
  await mongoose.connection.db.dropDatabase();
});

test('CORS accepte localhost dynamique et bloque une origine externe', async () => {
  const allowedResponse = await request(app)
    .get('/api/health')
    .set('Origin', 'http://localhost:3000');

  assert.equal(allowedResponse.status, 200);
  assert.equal(
    allowedResponse.headers['access-control-allow-origin'],
    'http://localhost:3000'
  );

  const deniedResponse = await request(app)
    .get('/api/health')
    .set('Origin', 'http://evil.example.com');

  assert.equal(deniedResponse.status, 403);
  assert.equal(deniedResponse.body.code, 'CORS_ORIGIN_DENIED');
});

test('register + login + profile ne fuit jamais le mot de passe', async () => {
  const faculty = await Faculty.create({
    name: 'Faculte des Sciences',
    slug: 'faculte-des-sciences',
  });

  const registerResponse = await request(app).post('/api/auth/register').send({
    name: 'Alice',
    email: 'alice@usmba.ac.ma',
    password: 'secret123',
    faculty: faculty._id.toString(),
    role: 'student',
  });

  assert.equal(registerResponse.status, 201);
  assert.equal(registerResponse.body.user.name, 'Alice');
  assert.equal(registerResponse.body.user.password, undefined);

  const createdUser = await User.findOne({ email: 'alice@usmba.ac.ma' }).select(
    '+password'
  );
  assert.ok(createdUser.password);
  assert.notEqual(createdUser.password, 'secret123');

  createdUser.emailVerified = true;
  await createdUser.save();

  const loginResponse = await request(app).post('/api/auth/login').send({
    email: 'alice@usmba.ac.ma',
    password: 'secret123',
  });

  assert.equal(loginResponse.status, 200);
  assert.ok(loginResponse.body.token);
  assert.equal(loginResponse.body.user.password, undefined);

  const profileResponse = await request(app)
    .get('/api/users/profile')
    .set('Authorization', `Bearer ${loginResponse.body.token}`);

  assert.equal(profileResponse.status, 200);
  assert.equal(profileResponse.body.user.password, undefined);
  assert.equal(profileResponse.body.user.faculty.name, 'Faculte des Sciences');
});

test('login active automatiquement un compte non verifie si la verification email est desactivee', async () => {
  process.env.REQUIRE_EMAIL_VERIFICATION = 'false';

  const faculty = await Faculty.create({
    name: 'Faculte Login',
    slug: 'faculte-login',
  });

  await User.create({
    name: 'Nora',
    email: 'nora@usmba.ac.ma',
    password: 'secret123',
    faculty: faculty._id,
    emailVerified: false,
    verificationCode: '654321',
  });

  const loginResponse = await request(app).post('/api/auth/login').send({
    email: 'nora@usmba.ac.ma',
    password: 'secret123',
  });

  assert.equal(loginResponse.status, 200);

  const refreshedUser = await User.findOne({ email: 'nora@usmba.ac.ma' });
  assert.equal(refreshedUser.emailVerified, true);
  assert.equal(refreshedUser.verificationCode, undefined);
});

test('les utilisateurs deja presents en base sont regularises quand la verification email est desactivee', async () => {
  process.env.REQUIRE_EMAIL_VERIFICATION = 'false';

  const faculty = await Faculty.create({
    name: 'Faculte Backfill',
    slug: 'faculte-backfill',
  });

  await User.create({
    name: 'Amine',
    email: 'amine@usmba.ac.ma',
    password: 'secret123',
    faculty: faculty._id,
    emailVerified: false,
    verificationCode: '111111',
  });

  const result = await backfillEmailVerificationIfDisabled();
  assert.equal(result.skipped, false);
  assert.equal(result.modifiedCount, 1);

  const refreshedUser = await User.findOne({ email: 'amine@usmba.ac.ma' });
  assert.equal(refreshedUser.emailVerified, true);
  assert.equal(refreshedUser.verificationCode, undefined);
});

test('follow/unfollow met a jour followers/following et genere une notification', async () => {
  const faculty = await Faculty.create({
    name: 'Faculte des Lettres',
    slug: 'faculte-des-lettres',
  });

  const alice = await User.create({
    name: 'Alice',
    email: 'alice@usmba.ac.ma',
    password: 'secret123',
    faculty: faculty._id,
    emailVerified: true,
  });
  const bob = await User.create({
    name: 'Bob',
    email: 'bob@usmba.ac.ma',
    password: 'secret123',
    faculty: faculty._id,
    emailVerified: true,
  });

  const aliceToken = signToken(alice);

  const followResponse = await request(app)
    .post(`/api/users/follow/${bob._id}`)
    .set('Authorization', `Bearer ${aliceToken}`);

  assert.equal(followResponse.status, 200);
  assert.equal(followResponse.body.user.followersCount, 1);

  const refreshedAlice = await User.findById(alice._id);
  const refreshedBob = await User.findById(bob._id);
  assert.equal(refreshedAlice.following.length, 1);
  assert.equal(refreshedBob.followers.length, 1);

  const notificationsResponse = await request(app)
    .get('/api/notifications')
    .set('Authorization', `Bearer ${signToken(bob)}`);

  assert.equal(notificationsResponse.status, 200);
  assert.equal(notificationsResponse.body.notifications.length, 1);
  assert.equal(notificationsResponse.body.notifications[0].type, 'follow');

  const contactsResponse = await request(app)
    .get('/api/users/contacts')
    .set('Authorization', `Bearer ${signToken(alice)}`);

  assert.equal(contactsResponse.status, 200);
  assert.equal(contactsResponse.body.contacts.length, 1);
  assert.equal(contactsResponse.body.contacts[0]._id, bob._id.toString());

  const unfollowResponse = await request(app)
    .post(`/api/users/unfollow/${bob._id}`)
    .set('Authorization', `Bearer ${aliceToken}`);

  assert.equal(unfollowResponse.status, 200);
});

test('feed renvoie un envelope pagine avec populate correct et filtre faculte', async () => {
  const science = await Faculty.create({
    name: 'Faculte des Sciences',
    slug: 'faculte-des-sciences',
  });
  const droit = await Faculty.create({
    name: 'Faculte de Droit',
    slug: 'faculte-de-droit',
  });

  const alice = await User.create({
    name: 'Alice',
    email: 'alice@usmba.ac.ma',
    password: 'secret123',
    faculty: science._id,
    emailVerified: true,
  });
  const bob = await User.create({
    name: 'Bob',
    email: 'bob@usmba.ac.ma',
    password: 'secret123',
    faculty: science._id,
    emailVerified: true,
  });

  alice.following.push(bob._id);
  await alice.save();

  await Post.create({
    user: bob._id,
    content: 'Post science',
    faculty: science._id,
  });
  await Post.create({
    user: bob._id,
    content: 'Post droit',
    faculty: droit._id,
  });

  const response = await request(app)
    .get(`/api/posts?page=1&limit=10&faculty=${science._id}`)
    .set('Authorization', `Bearer ${signToken(alice)}`);

  assert.equal(response.status, 200);
  assert.ok(Array.isArray(response.body.posts));
  assert.equal(response.body.posts[0].user.name, 'Bob');
  assert.ok(response.body.pagination);
});

test('messages conversations et admin dashboard fonctionnent avec les nouveaux contrats', async () => {
  const faculty = await Faculty.create({
    name: 'Faculte Admin',
    slug: 'faculte-admin',
  });

  const admin = await User.create({
    name: 'Admin',
    email: 'admin@usmba.ac.ma',
    password: 'secret123',
    faculty: faculty._id,
    role: 'admin',
    emailVerified: true,
  });
  const alice = await User.create({
    name: 'Alice',
    email: 'alice@usmba.ac.ma',
    password: 'secret123',
    faculty: faculty._id,
    emailVerified: true,
  });
  const bob = await User.create({
    name: 'Bob',
    email: 'bob@usmba.ac.ma',
    password: 'secret123',
    faculty: faculty._id,
    emailVerified: true,
  });

  const post = await Post.create({
    user: bob._id,
    content: 'Post a moderer',
    faculty: faculty._id,
  });

  await Message.create({
    sender: alice._id,
    receiver: bob._id,
    content: 'Bonjour Bob',
  });

  await Report.create({
    post: post._id,
    user: bob._id,
    reportedBy: alice._id,
    reason: 'spam',
    status: 'pending',
  });

  const conversationsResponse = await request(app)
    .get('/api/messages/conversations')
    .set('Authorization', `Bearer ${signToken(alice)}`);

  assert.equal(conversationsResponse.status, 200);
  assert.equal(conversationsResponse.body.conversations.length, 1);
  assert.equal(conversationsResponse.body.conversations[0].user.name, 'Bob');

  const dashboardResponse = await request(app)
    .get('/api/admin/dashboard')
    .set('Authorization', `Bearer ${signToken(admin)}`);

  assert.equal(dashboardResponse.status, 200);
  assert.equal(dashboardResponse.body.stats.totalUsers, 3);
  assert.equal(dashboardResponse.body.stats.totalReports, 1);

  const reportsResponse = await request(app)
    .get('/api/admin/reports')
    .set('Authorization', `Bearer ${signToken(admin)}`);

  assert.equal(reportsResponse.status, 200);
  assert.equal(reportsResponse.body.reports.length, 1);

  const postsResponse = await request(app)
    .get('/api/admin/posts')
    .set('Authorization', `Bearer ${signToken(admin)}`);

  assert.equal(postsResponse.status, 200);
  assert.equal(postsResponse.body.posts.length, 1);
  assert.equal(postsResponse.body.posts[0].content, 'Post a moderer');

  const deletePostResponse = await request(app)
    .delete(`/api/admin/posts/${post._id}`)
    .set('Authorization', `Bearer ${signToken(admin)}`);

  assert.equal(deletePostResponse.status, 200);

  const deletedPost = await Post.findById(post._id);
  assert.equal(deletedPost, null);
});

test('messages acceptent des pieces jointes et les stories suivent le graphe social', async () => {
  const faculty = await Faculty.create({
    name: 'Faculte Media',
    slug: 'faculte-media',
  });

  const alice = await User.create({
    name: 'Alice',
    email: 'alice.media@usmba.ac.ma',
    password: 'secret123',
    faculty: faculty._id,
    emailVerified: true,
  });
  const bob = await User.create({
    name: 'Bob',
    email: 'bob.media@usmba.ac.ma',
    password: 'secret123',
    faculty: faculty._id,
    emailVerified: true,
  });

  alice.following.push(bob._id);
  bob.followers.push(alice._id);
  await Promise.all([alice.save(), bob.save()]);

  const messageResponse = await request(app)
    .post('/api/messages')
    .set('Authorization', `Bearer ${signToken(alice)}`)
    .field('receiver', bob._id.toString())
    .field('content', 'Cours en piece jointe')
    .attach('attachments', Buffer.from('fake pdf'), 'cours.pdf');

  assert.equal(messageResponse.status, 201);
  assert.equal(messageResponse.body.data.attachments.length, 1);
  assert.equal(messageResponse.body.data.attachments[0].kind, 'document');
  assert.equal(messageResponse.body.notification.type, 'message');

  const imageMessageResponse = await request(app)
    .post('/api/messages')
    .set('Authorization', `Bearer ${signToken(alice)}`)
    .field('receiver', bob._id.toString())
    .attach('attachments', Buffer.from('fake image'), 'photo.png');

  assert.equal(imageMessageResponse.status, 201);
  assert.equal(imageMessageResponse.body.data.attachments[0].kind, 'image');

  const bobNotificationsAfterMessage = await request(app)
    .get('/api/notifications')
    .set('Authorization', `Bearer ${signToken(bob)}`);

  assert.equal(bobNotificationsAfterMessage.status, 200);
  assert.equal(bobNotificationsAfterMessage.body.notifications[0].type, 'message');

  const postResponse = await request(app)
    .post('/api/posts')
    .set('Authorization', `Bearer ${signToken(bob)}`)
    .send({ content: 'Nouveau post pour mes abonnes' });

  assert.equal(postResponse.status, 201);

  const aliceNotificationsAfterPost = await request(app)
    .get('/api/notifications')
    .set('Authorization', `Bearer ${signToken(alice)}`);

  assert.equal(aliceNotificationsAfterPost.status, 200);
  assert.equal(aliceNotificationsAfterPost.body.notifications[0].type, 'post');

  const storyCreateResponse = await request(app)
    .post('/api/stories')
    .set('Authorization', `Bearer ${signToken(bob)}`)
    .field('caption', 'Nouvelle story')
    .attach('media', Buffer.from('fake image'), 'story.png');

  assert.equal(storyCreateResponse.status, 201);
  assert.equal(storyCreateResponse.body.story.caption, 'Nouvelle story');

  const storyFeedResponse = await request(app)
    .get('/api/stories/feed')
    .set('Authorization', `Bearer ${signToken(alice)}`);

  assert.equal(storyFeedResponse.status, 200);
  assert.equal(storyFeedResponse.body.stories.length, 1);
  assert.equal(storyFeedResponse.body.stories[0].user.name, 'Bob');

  const viewStoryResponse = await request(app)
    .post(`/api/stories/${storyFeedResponse.body.stories[0]._id}/view`)
    .set('Authorization', `Bearer ${signToken(alice)}`);

  assert.equal(viewStoryResponse.status, 200);
  assert.equal(viewStoryResponse.body.story.hasViewed, true);

  const persistedStory = await Story.findById(storyFeedResponse.body.stories[0]._id);
  assert.equal(persistedStory.viewers.length, 1);
});
