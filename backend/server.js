const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcryptjs = require('bcryptjs');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const http = require('http');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');

const User = require('./models/User');
const Post = require('./models/Post');
const Message = require('./models/Message');
const Faculty = require('./models/Faculty');
const Comment = require('./models/Comment');
const Save = require('./models/Save');
const Report = require('./models/Report');
const Group = require('./models/Group');
const Event = require('./models/Event');
const Notification = require('./models/Notification');

const app = express();
const server = http.createServer(app);
const io = require('socket.io')(server, { cors: { origin: "*" } });

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Create uploads directory if it doesn't exist
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

app.use('/uploads', express.static(uploadsDir));

// Multer configuration
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadsDir);
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + '-' + file.originalname);
  }
});

const upload = multer({ 
  storage: storage,
  limits: { fileSize: 50 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowedMimes = ['image/jpeg', 'image/png', 'image/gif', 'video/mp4', 'video/webm', 'application/pdf'];
    if (allowedMimes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('File type not allowed'));
    }
  }
});

const JWT_SECRET = process.env.JWT_SECRET || 'dev_jwt_secret_change_me';

// ============ MIDDLEWARE ============
function auth(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader) return res.status(401).json({ message: 'No token provided' });
  
  const token = authHeader.split(' ')[1];
  try {
    const payload = jwt.verify(token, JWT_SECRET);
    req.userId = payload.id;
    next();
  } catch (e) {
    return res.status(401).json({ message: 'Invalid token' });
  }
}

function adminOnly(req, res, next) {
  auth(req, res, async () => {
    try {
      const user = await User.findById(req.userId);
      if (user.role !== 'admin') {
        return res.status(403).json({ message: 'Admin only' });
      }
      next();
    } catch (e) {
      res.status(500).json({ message: e.message });
    }
  });
}

function extractHashtagsAndMentions(text) {
  const hashtags = (text.match(/#\w+/g) || []).map(h => h.substring(1).toLowerCase());
  const mentions = text.match(/@\w+/g) || [];
  return { hashtags, mentions };
}

// ============ AUTH ROUTES ============
app.post('/register', upload.single('avatar'), async (req, res) => {
  try {
    const { nom, prenom, email, password, faculty, filiere, niveau, bio } = req.body;

    if (!nom || !email || !password) {
      return res.status(400).json({ message: 'Nom, email et mot de passe requis' });
    }

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'Cet email est déjà utilisé' });
    }

    const passwordHash = await bcryptjs.hash(password, 10);
    const avatarUrl = req.file ? `/uploads/${req.file.filename}` : null;
    const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();

    let facultyId = null;
    if (faculty) {
      const facultyName = faculty.toString();
      let fac = await Faculty.findOne({ name: facultyName });
      if (!fac) {
        const slug = facultyName.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
        fac = await Faculty.create({ name: facultyName, slug });
      }
      facultyId = fac._id;
    }

    const user = await User.create({
      nom,
      prenom: prenom || '',
      email,
      passwordHash,
      faculty: facultyId,
      filiere: filiere || '',
      niveau: niveau || '',
      bio: bio || '',
      avatarUrl,
      isVerified: false,
      verificationCode
    });

    const token = jwt.sign({ id: user._id }, JWT_SECRET, { expiresIn: '7d' });

    res.status(201).json({
      token,
      verificationCode,
      user: {
        id: user._id,
        nom: user.nom,
        email: user.email,
        faculty: user.faculty,
        isVerified: user.isVerified
      }
    });
  } catch (e) {
    console.error('Register error:', e);
    res.status(500).json({ message: 'Erreur serveur: ' + e.message });
  }
});

app.post('/auth/verify-email', async (req, res) => {
  try {
    const { email, code } = req.body;
    if (!email || !code) return res.status(400).json({ message: 'Email et code requis' });
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'Utilisateur non trouvé' });
    if (user.isVerified) return res.json({ ok: true, message: 'Déjà vérifié' });
    if (user.verificationCode === code) {
      user.isVerified = true;
      user.verificationCode = null;
      await user.save();
      return res.json({ ok: true });
    }
    return res.status(400).json({ message: 'Code invalide' });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.post('/auth/request-password-reset', async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ message: 'Email requis' });
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'Utilisateur non trouvé' });
    const token = crypto.randomBytes(20).toString('hex');
    user.resetPasswordToken = token;
    user.resetPasswordExpires = Date.now() + 3600000;
    await user.save();
    res.json({ ok: true, resetToken: token });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.post('/auth/reset-password', async (req, res) => {
  try {
    const { token, newPassword } = req.body;
    if (!token || !newPassword) return res.status(400).json({ message: 'Token et nouveau mot de passe requis' });
    const user = await User.findOne({ resetPasswordToken: token, resetPasswordExpires: { $gt: Date.now() } });
    if (!user) return res.status(400).json({ message: 'Token invalide ou expiré' });
    user.passwordHash = await bcryptjs.hash(newPassword, 10);
    user.resetPasswordToken = null;
    user.resetPasswordExpires = null;
    await user.save();
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// Login
app.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Email et mot de passe requis' });
    }

    const user = await User.findOne({ email })
      .populate('faculty', 'name slug')
      .select('+passwordHash');
    
    if (!user) {
      return res.status(400).json({ message: 'Email ou mot de passe incorrect' });
    }

    const passwordValid = await bcryptjs.compare(password, user.passwordHash);
    if (!passwordValid) {
      return res.status(400).json({ message: 'Email ou mot de passe incorrect' });
    }

    const token = jwt.sign({ id: user._id }, JWT_SECRET, { expiresIn: '7d' });

    res.json({
      token,
      user: {
        id: user._id,
        nom: user.nom,
        email: user.email,
        avatarUrl: user.avatarUrl,
        faculty: user.faculty,
        isVerified: user.isVerified
      }
    });
  } catch (e) {
    console.error('Login error:', e);
    res.status(500).json({ message: 'Erreur serveur: ' + e.message });
  }
});

app.post('/auth/verify-email', async (req, res) => {
  try {
    const { email, code } = req.body;
    if (!email || !code) return res.status(400).json({ message: 'Email et code requis' });
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'Utilisateur non trouvé' });
    if (user.isVerified) return res.json({ ok: true, message: 'Déjà vérifié' });
    if (user.verificationCode === code) {
      user.isVerified = true;
      user.verificationCode = null;
      await user.save();
      return res.json({ ok: true });
    }
    return res.status(400).json({ message: 'Code invalide' });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.post('/auth/request-password-reset', async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ message: 'Email requis' });
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'Utilisateur non trouvé' });
    const token = crypto.randomBytes(20).toString('hex');
    user.resetPasswordToken = token;
    user.resetPasswordExpires = Date.now() + 3600000;
    await user.save();
    res.json({ ok: true, resetToken: token });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.post('/auth/reset-password', async (req, res) => {
  try {
    const { token, newPassword } = req.body;
    if (!token || !newPassword) return res.status(400).json({ message: 'Token et nouveau mot de passe requis' });
    const user = await User.findOne({ resetPasswordToken: token, resetPasswordExpires: { $gt: Date.now() } });
    if (!user) return res.status(400).json({ message: 'Token invalide ou expiré' });
    user.passwordHash = await bcryptjs.hash(newPassword, 10);
    user.resetPasswordToken = null;
    user.resetPasswordExpires = null;
    await user.save();
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// ============ USER ROUTES ============
app.get('/user/:id', async (req, res) => {
  try {
    const user = await User.findById(req.params.id)
      .populate('faculty', 'name slug')
      .populate('followers', 'nom avatarUrl')
      .populate('following', 'nom avatarUrl');
    
    if (!user) {
      return res.status(404).json({ message: 'Utilisateur non trouvé' });
    }

    res.json(user);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.put('/user/:id', auth, upload.single('avatar'), async (req, res) => {
  try {
    if (req.userId !== req.params.id && (await User.findById(req.userId)).role !== 'admin') {
      return res.status(403).json({ message: 'Unauthorized' });
    }

    const { nom, prenom, bio, filiere, niveau, interests } = req.body;
    const updateData = {};

    if (nom) updateData.nom = nom;
    if (prenom) updateData.prenom = prenom;
    if (bio !== undefined) updateData.bio = bio;
    if (filiere) updateData.filiere = filiere;
    if (niveau) updateData.niveau = niveau;
    if (interests) updateData.interests = interests.split(',').map(i => i.trim());
    if (req.file) updateData.avatarUrl = `/uploads/${req.file.filename}`;

    const user = await User.findByIdAndUpdate(req.params.id, updateData, { new: true });
    res.json(user);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.post('/follow/:id', auth, async (req, res) => {
  try {
    const toFollowId = req.params.id;

    if (req.userId === toFollowId) {
      return res.status(400).json({ message: 'Vous ne pouvez pas vous suivre' });
    }

    const me = await User.findById(req.userId);
    const userToFollow = await User.findById(toFollowId);

    if (!userToFollow) {
      return res.status(404).json({ message: 'Utilisateur non trouvé' });
    }

    if (!me.following.includes(toFollowId)) {
      me.following.push(toFollowId);
      me.followingCount = me.following.length;
      userToFollow.followers.push(req.userId);
      userToFollow.followersCount = userToFollow.followers.length;
    }

    await me.save();
    await userToFollow.save();

    await Notification.create({
      recipient: toFollowId,
      sender: req.userId,
      type: 'follow',
      message: `${me.nom} vous suit maintenant`
    });

    io.to(toFollowId).emit('notification', { type: 'follow', from: req.userId });

    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.post('/unfollow/:id', auth, async (req, res) => {
  try {
    const toUnfollowId = req.params.id;
    const me = await User.findById(req.userId);
    const userToUnfollow = await User.findById(toUnfollowId);

    me.following = me.following.filter(f => f.toString() !== toUnfollowId);
    me.followingCount = me.following.length;
    userToUnfollow.followers = userToUnfollow.followers.filter(f => f.toString() !== req.userId);
    userToUnfollow.followersCount = userToUnfollow.followers.length;

    await me.save();
    await userToUnfollow.save();

    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.post('/block/:id', auth, async (req, res) => {
  try {
    const toBlockId = req.params.id;
    const me = await User.findById(req.userId);

    if (!me.blocked.includes(toBlockId)) {
      me.blocked.push(toBlockId);
    }

    await me.save();
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// ============ POSTS ROUTES ============
app.post('/posts', auth, upload.single('media'), async (req, res) => {
  try {
    const { text, isPublic, faculty, group } = req.body;
    const mediaUrl = req.file ? `/uploads/${req.file.filename}` : null;

    const { hashtags, mentions } = extractHashtagsAndMentions(text || '');

    const post = await Post.create({
      author: req.userId,
      text,
      mediaUrl,
      mediaType: req.file ? req.file.mimetype : null,
      hashtags,
      mentions,
      isPublic: isPublic !== 'false',
      faculty: faculty || null,
      group: group || null
    });

    await User.findByIdAndUpdate(req.userId, { $inc: { postsCount: 1 } });

    const populatedPost = await post.populate('author', 'nom prenom avatarUrl faculty').populate('faculty', 'name');
    res.status(201).json(populatedPost);
  } catch (e) {
    console.error('Post create error:', e);
    res.status(500).json({ message: e.message });
  }
});

app.get('/posts', async (req, res) => {
  try {
    const { page = 1, limit = 10, facultyId, groupId } = req.query;
    const skip = (page - 1) * limit;

    let query = { isPublic: true };
    if (facultyId) query.faculty = facultyId;
    if (groupId) query.group = groupId;

    const posts = await Post.find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .populate('author', 'nom prenom avatarUrl faculty')
      .populate('faculty', 'name');

    const total = await Post.countDocuments(query);

    res.json({ posts, total, page: parseInt(page), pages: Math.ceil(total / limit) });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.get('/posts/user/:userId', async (req, res) => {
  try {
    const { page = 1, limit = 10 } = req.query;
    const skip = (page - 1) * limit;

    const posts = await Post.find({ author: req.params.userId })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .populate('author', 'nom prenom avatarUrl');

    const total = await Post.countDocuments({ author: req.params.userId });

    res.json({ posts, total, page: parseInt(page), pages: Math.ceil(total / limit) });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.get('/posts/:id', async (req, res) => {
  try {
    const post = await Post.findById(req.params.id)
      .populate('author', 'nom prenom avatarUrl')
      .populate('likes', 'nom');

    if (!post) return res.status(404).json({ message: 'Post non trouvé' });

    res.json(post);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.post('/posts/:id/like', auth, async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) {
      return res.status(404).json({ message: 'Post non trouvé' });
    }

    if (post.likes.includes(req.userId)) {
      post.likes = post.likes.filter(id => id.toString() !== req.userId);
      post.likesCount = Math.max(0, post.likesCount - 1);
    } else {
      post.likes.push(req.userId);
      post.likesCount = post.likes.length;

      if (post.author.toString() !== req.userId) {
        const author = await User.findById(post.author);
        await Notification.create({
          recipient: post.author,
          sender: req.userId,
          type: 'like',
          relatedPost: post._id,
          message: `${author.nom} a aimé votre post`
        });
        io.to(post.author.toString()).emit('notification', { type: 'like', postId: post._id });
      }
    }

    await post.save();
    res.json({ ok: true, likesCount: post.likesCount });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.post('/posts/:id/comment', auth, async (req, res) => {
  try {
    const { text } = req.body;
    if (!text) return res.status(400).json({ message: 'Texte requis' });

    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ message: 'Post non trouvé' });

    const comment = await Comment.create({
      post: req.params.id,
      author: req.userId,
      text
    });

    post.commentsCount = (post.commentsCount || 0) + 1;
    await post.save();

    const populatedComment = await comment.populate('author', 'nom prenom avatarUrl');

    if (post.author.toString() !== req.userId) {
      const user = await User.findById(req.userId);
      await Notification.create({
        recipient: post.author,
        sender: req.userId,
        type: 'comment',
        relatedPost: post._id,
        message: `${user.nom} a commenté votre post`
      });
      io.to(post.author.toString()).emit('notification', { type: 'comment', postId: post._id });
    }

    res.status(201).json(populatedComment);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.get('/posts/:id/comments', async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const skip = (page - 1) * limit;

    const comments = await Comment.find({ post: req.params.id })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .populate('author', 'nom prenom avatarUrl');

    const total = await Comment.countDocuments({ post: req.params.id });

    res.json({ comments, total, page: parseInt(page), pages: Math.ceil(total / limit) });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.delete('/posts/:id', auth, async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ message: 'Post non trouvé' });

    if (post.author.toString() !== req.userId && (await User.findById(req.userId)).role !== 'admin') {
      return res.status(403).json({ message: 'Unauthorized' });
    }

    await Post.findByIdAndDelete(req.params.id);
    await Comment.deleteMany({ post: req.params.id });
    await User.findByIdAndUpdate(post.author, { $inc: { postsCount: -1 } });

    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.post('/posts/:id/save', auth, async (req, res) => {
  try {
    const existingSave = await Save.findOne({ post: req.params.id, user: req.userId });
    if (existingSave) {
      await Save.deleteOne({ _id: existingSave._id });
      const post = await Post.findById(req.params.id);
      post.savesCount = Math.max(0, (post.savesCount || 0) - 1);
      await post.save();
      return res.json({ ok: true, saved: false });
    }

    await Save.create({ post: req.params.id, user: req.userId });
    const post = await Post.findById(req.params.id);
    post.savesCount = (post.savesCount || 0) + 1;
    await post.save();

    res.json({ ok: true, saved: true });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.post('/posts/:id/report', auth, async (req, res) => {
  try {
    const { reason, description } = req.body;
    if (!reason) return res.status(400).json({ message: 'Raison requise' });

    const existingReport = await Report.findOne({ post: req.params.id, reportedBy: req.userId });
    if (existingReport) {
      return res.status(400).json({ message: 'Vous avez déjà signalé ce post' });
    }

    await Report.create({
      post: req.params.id,
      reportedBy: req.userId,
      reason,
      description,
      status: 'pending'
    });

    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// ============ FACULTIES ROUTES ============
app.get('/faculties', async (req, res) => {
  try {
    const faculties = await Faculty.find().sort({ name: 1 });
    res.json(faculties);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.get('/faculties/:id', async (req, res) => {
  try {
    const faculty = await Faculty.findById(req.params.id);
    if (!faculty) return res.status(404).json({ message: 'Faculté non trouvée' });
    res.json(faculty);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.get('/faculties/:id/posts', async (req, res) => {
  try {
    const { page = 1, limit = 10 } = req.query;
    const skip = (page - 1) * limit;

    const posts = await Post.find({ faculty: req.params.id })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .populate('author', 'nom prenom avatarUrl');

    const total = await Post.countDocuments({ faculty: req.params.id });

    res.json({ posts, total, page: parseInt(page), pages: Math.ceil(total / limit) });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.get('/faculties/:id/members', async (req, res) => {
  try {
    const { page = 1, limit = 50 } = req.query;
    const skip = (page - 1) * limit;

    const members = await User.find({ faculty: req.params.id })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .select('nom prenom avatarUrl filiere niveau');

    const total = await User.countDocuments({ faculty: req.params.id });

    res.json({ members, total, page: parseInt(page), pages: Math.ceil(total / limit) });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// ============ GROUPS ROUTES ============
app.post('/groups', auth, upload.single('avatar'), async (req, res) => {
  try {
    const { name, description, category, isPrivate, faculty } = req.body;
    if (!name) return res.status(400).json({ message: 'Nom requis' });

    const avatar = req.file ? `/uploads/${req.file.filename}` : null;

    const group = await Group.create({
      name,
      description,
      avatar,
      category,
      isPrivate: isPrivate === 'true',
      faculty,
      owner: req.userId,
      members: [req.userId],
      admins: [req.userId]
    });

    res.status(201).json(group);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.get('/groups', async (req, res) => {
  try {
    const { page = 1, limit = 10, category } = req.query;
    const skip = (page - 1) * limit;

    let query = { isPrivate: false };
    if (category) query.category = category;

    const groups = await Group.find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .populate('owner', 'nom prenom avatarUrl');

    const total = await Group.countDocuments(query);

    res.json({ groups, total, page: parseInt(page), pages: Math.ceil(total / limit) });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.get('/groups/:id', async (req, res) => {
  try {
    const group = await Group.findById(req.params.id)
      .populate('owner', 'nom prenom avatarUrl')
      .populate('members', 'nom prenom avatarUrl');
    if (!group) return res.status(404).json({ message: 'Groupe non trouvé' });
    res.json(group);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.post('/groups/:id/join', auth, async (req, res) => {
  try {
    const group = await Group.findById(req.params.id);
    if (!group) return res.status(404).json({ message: 'Groupe non trouvé' });

    if (!group.members.includes(req.userId)) {
      group.members.push(req.userId);
      await group.save();
    }

    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.post('/groups/:id/leave', auth, async (req, res) => {
  try {
    const group = await Group.findById(req.params.id);
    if (!group) return res.status(404).json({ message: 'Groupe non trouvé' });

    group.members = group.members.filter(m => m.toString() !== req.userId);
    await group.save();

    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.get('/groups/:id/posts', async (req, res) => {
  try {
    const { page = 1, limit = 10 } = req.query;
    const skip = (page - 1) * limit;

    const posts = await Post.find({ group: req.params.id })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .populate('author', 'nom prenom avatarUrl');

    const total = await Post.countDocuments({ group: req.params.id });

    res.json({ posts, total, page: parseInt(page), pages: Math.ceil(total / limit) });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// ============ EVENTS ROUTES ============
app.post('/events', auth, upload.single('image'), async (req, res) => {
  try {
    const { title, description, startDate, endDate, location, category, maxAttendees, faculty, group } = req.body;
    if (!title || !startDate) return res.status(400).json({ message: 'Titre et date requises' });

    const image = req.file ? `/uploads/${req.file.filename}` : null;

    const event = await Event.create({
      title,
      description,
      image,
      startDate,
      endDate,
      location,
      category,
      maxAttendees,
      faculty,
      group,
      organizer: req.userId,
      attendees: [req.userId]
    });

    res.status(201).json(event);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.get('/events', async (req, res) => {
  try {
    const { page = 1, limit = 10, category, faculty } = req.query;
    const skip = (page - 1) * limit;

    let query = { startDate: { $gte: new Date() } };
    if (category) query.category = category;
    if (faculty) query.faculty = faculty;

    const events = await Event.find(query)
      .sort({ startDate: 1 })
      .skip(skip)
      .limit(parseInt(limit))
      .populate('organizer', 'nom prenom avatarUrl');

    const total = await Event.countDocuments(query);

    res.json({ events, total, page: parseInt(page), pages: Math.ceil(total / limit) });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.get('/events/:id', async (req, res) => {
  try {
    const event = await Event.findById(req.params.id)
      .populate('organizer', 'nom prenom avatarUrl')
      .populate('attendees', 'nom prenom avatarUrl');
    if (!event) return res.status(404).json({ message: 'Événement non trouvé' });
    res.json(event);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.post('/events/:id/rsvp', auth, async (req, res) => {
  try {
    const event = await Event.findById(req.params.id);
    if (!event) return res.status(404).json({ message: 'Événement non trouvé' });

    if (event.attendees.includes(req.userId)) {
      event.attendees = event.attendees.filter(a => a.toString() !== req.userId);
    } else {
      if (event.maxAttendees && event.attendees.length >= event.maxAttendees) {
        return res.status(400).json({ message: 'Événement complet' });
      }
      event.attendees.push(req.userId);
    }

    await event.save();
    res.json({ ok: true, attendeesCount: event.attendees.length });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// ============ NOTIFICATIONS ROUTES ============
app.get('/notifications', auth, async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const skip = (page - 1) * limit;

    const notifications = await Notification.find({ recipient: req.userId })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .populate('sender', 'nom prenom avatarUrl');

    const total = await Notification.countDocuments({ recipient: req.userId });
    const unread = await Notification.countDocuments({ recipient: req.userId, isRead: false });

    res.json({ notifications, total, unread, page: parseInt(page), pages: Math.ceil(total / limit) });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.put('/notifications/:id/read', auth, async (req, res) => {
  try {
    await Notification.findByIdAndUpdate(req.params.id, { isRead: true });
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.delete('/notifications/:id', auth, async (req, res) => {
  try {
    await Notification.findByIdAndDelete(req.params.id);
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// ============ SEARCH ROUTES ============
app.get('/search', async (req, res) => {
  try {
    const { q, type } = req.query;
    if (!q) return res.status(400).json({ message: 'Query requis' });

    const results = {};

    if (!type || type === 'users') {
      results.users = await User.find({
        $or: [
          { nom: { $regex: q, $options: 'i' } },
          { email: { $regex: q, $options: 'i' } }
        ]
      }).select('nom prenom avatarUrl faculty').limit(10);
    }

    if (!type || type === 'posts') {
      results.posts = await Post.find({
        $or: [
          { text: { $regex: q, $options: 'i' } },
          { hashtags: { $regex: q, $options: 'i' } }
        ]
      }).populate('author', 'nom prenom avatarUrl').limit(10);
    }

    if (!type || type === 'groups') {
      results.groups = await Group.find({
        name: { $regex: q, $options: 'i' }
      }).populate('owner', 'nom prenom avatarUrl').limit(10);
    }

    if (!type || type === 'faculties') {
      results.faculties = await Faculty.find({
        name: { $regex: q, $options: 'i' }
      }).limit(10);
    }

    res.json(results);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// ============ ADMIN ROUTES ============
app.get('/admin/reports', adminOnly, async (req, res) => {
  try {
    const { status = 'pending', page = 1, limit = 20 } = req.query;
    const skip = (page - 1) * limit;

    const reports = await Report.find({ status })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .populate('reportedBy', 'nom')
      .populate('post')
      .populate('user')
      .populate('comment');

    const total = await Report.countDocuments({ status });

    res.json({ reports, total, page: parseInt(page), pages: Math.ceil(total / limit) });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.put('/admin/reports/:id', adminOnly, async (req, res) => {
  try {
    const { status, action } = req.body;
    const report = await Report.findByIdAndUpdate(req.params.id, { status, action }, { new: true });

    if (action === 'removed' && report.post) {
      await Post.findByIdAndDelete(report.post);
    }
    if (action === 'suspended' || action === 'banned' && report.user) {
      await User.findByIdAndUpdate(report.user, { isVerified: false });
    }

    res.json(report);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.get('/admin/users', adminOnly, async (req, res) => {
  try {
    const { page = 1, limit = 20, role } = req.query;
    const skip = (page - 1) * limit;

    let query = {};
    if (role) query.role = role;

    const users = await User.find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await User.countDocuments(query);

    res.json({ users, total, page: parseInt(page), pages: Math.ceil(total / limit) });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.get('/admin/dashboard', adminOnly, async (req, res) => {
  try {
    const totalUsers = await User.countDocuments();
    const totalPosts = await Post.countDocuments();
    const totalGroups = await Group.countDocuments();
    const totalEvents = await Event.countDocuments();
    const pendingReports = await Report.countDocuments({ status: 'pending' });

    res.json({
      totalUsers,
      totalPosts,
      totalGroups,
      totalEvents,
      pendingReports
    });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

// ============ MESSAGES & SOCKET.IO ============
app.post('/messages', auth, async (req, res) => {
  try {
    const { to, text } = req.body;

    if (!to || !text) {
      return res.status(400).json({ message: 'Destinataire et message requis' });
    }

    const message = await Message.create({
      from: req.userId,
      to,
      text
    });

    io.to(to).emit('newMessage', message);

    res.status(201).json(message);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.get('/messages/:userId', auth, async (req, res) => {
  try {
    const messages = await Message.find({
      $or: [
        { from: req.userId, to: req.params.userId },
        { from: req.params.userId, to: req.userId }
      ]
    }).sort({ createdAt: 1 });

    res.json(messages);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

app.get('/conversations', auth, async (req, res) => {
  try {
    const conversations = await Message.aggregate([
      {
        $match: {
          $or: [{ from: mongoose.Types.ObjectId(req.userId) }, { to: mongoose.Types.ObjectId(req.userId) }]
        }
      },
      { $sort: { createdAt: -1 } },
      {
        $group: {
          _id: {
            $cond: [
              { $eq: ['$from', mongoose.Types.ObjectId(req.userId)] },
              '$to',
              '$from'
            ]
          },
          lastMessage: { $first: '$text' },
          lastTime: { $first: '$createdAt' }
        }
      },
      { $limit: 50 }
    ]);

    res.json(conversations);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
});

io.on('connection', (socket) => {
  console.log('User connected:', socket.id);

  socket.on('join', (userId) => {
    socket.join(userId);
    console.log('User joined room:', userId);
  });

  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

// ============ START SERVER ============
async function startServer() {
  try {
    await mongoose.connect('mongodb://127.0.0.1:27017/usmba_social', {
      serverSelectionTimeoutMS: 5000
    });
    console.log('✅ MongoDB connected');

    const PORT = process.env.PORT || 5000;
    server.listen(PORT, () => {
      console.log(`🚀 Server running on http://localhost:${PORT}`);
    });
  } catch (err) {
    console.error('❌ MongoDB connection failed:', err.message);
    console.log('Retrying in 5s...');
    setTimeout(startServer, 5000);
  }
}

startServer();

module.exports = server;