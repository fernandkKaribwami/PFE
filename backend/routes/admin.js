const express = require('express');

const auth = require('../middleware/auth');
const Post = require('../models/Post');
const Report = require('../models/Report');
const User = require('../models/User');
const { createHttpError } = require('../utils/httpError');
const {
  serializePost,
  serializeReport,
  serializeUserSummary,
} = require('../utils/serializers');

const router = express.Router();

const ensureAdmin = (req) => {
  if (req.user.role !== 'admin') {
    throw createHttpError(403, 'Admin uniquement', 'ADMIN_ONLY');
  }
};

router.get('/dashboard', auth, async (req, res) => {
  ensureAdmin(req);

  const [totalUsers, totalPosts, totalReports, blockedUsers] = await Promise.all([
    User.countDocuments(),
    Post.countDocuments(),
    Report.countDocuments({ status: 'pending' }),
    User.countDocuments({ blocked: true }),
  ]);

  res.json({
    success: true,
    stats: {
      totalUsers,
      totalPosts,
      totalReports,
      blockedUsers,
    },
  });
});

router.get('/users', auth, async (req, res) => {
  ensureAdmin(req);

  const page = Math.max(1, parseInt(req.query.page, 10) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(req.query.limit, 10) || 20));
  const filter = {};

  if (req.query.role) {
    filter.role = req.query.role;
  }
  if (req.query.blocked === 'true') {
    filter.blocked = true;
  }
  if (req.query.search) {
    filter.$or = [
      { name: { $regex: req.query.search, $options: 'i' } },
      { email: { $regex: req.query.search, $options: 'i' } },
    ];
  }

  const total = await User.countDocuments(filter);
  const users = await User.find(filter)
    .populate('faculty', 'name slug image location')
    .sort({ createdAt: -1 })
    .skip((page - 1) * limit)
    .limit(limit)
    .lean();

  res.json({
    success: true,
    users: users.map((user) => serializeUserSummary(user)),
    pagination: {
      page,
      limit,
      total,
      hasMore: page * limit < total,
    },
  });
});

router.get('/posts', auth, async (req, res) => {
  ensureAdmin(req);

  const page = Math.max(1, parseInt(req.query.page, 10) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(req.query.limit, 10) || 20));
  const filter = {};

  if (req.query.search) {
    filter.content = { $regex: req.query.search, $options: 'i' };
  }

  const total = await Post.countDocuments(filter);
  const posts = await Post.find(filter)
    .populate({
      path: 'user',
      select: 'name email role avatar bio faculty level interests blocked createdAt updatedAt',
      populate: { path: 'faculty', select: 'name slug image location' },
    })
    .populate({
      path: 'faculty',
      select: 'name slug image location',
    })
    .sort({ createdAt: -1 })
    .skip((page - 1) * limit)
    .limit(limit)
    .lean();

  const postIds = posts.map((post) => post._id);
  const pendingReports = postIds.length
    ? await Report.aggregate([
        {
          $match: {
            post: { $in: postIds },
            status: 'pending',
          },
        },
        {
          $group: {
            _id: '$post',
            count: { $sum: 1 },
          },
        },
      ])
    : [];

  const reportsByPostId = new Map(
    pendingReports.map((item) => [item._id.toString(), item.count])
  );

  res.json({
    success: true,
    posts: posts.map((post) => ({
      ...serializePost(post, req.user.id),
      pendingReportsCount: reportsByPostId.get(post._id.toString()) || 0,
      isReported:
        post.isReported === true ||
        (reportsByPostId.get(post._id.toString()) || 0) > 0,
    })),
    pagination: {
      page,
      limit,
      total,
      hasMore: page * limit < total,
    },
  });
});

router.patch('/users/:id/block', auth, async (req, res) => {
  ensureAdmin(req);

  const user = await User.findById(req.params.id);
  if (!user) {
    throw createHttpError(404, 'Utilisateur introuvable', 'USER_NOT_FOUND');
  }

  user.blocked = !user.blocked;
  await user.save();

  res.json({
    success: true,
    message: `Utilisateur ${user.blocked ? 'bloque' : 'debloque'}`,
    user: {
      _id: user._id.toString(),
      blocked: user.blocked,
    },
  });
});

router.get('/reports', auth, async (req, res) => {
  ensureAdmin(req);

  const page = Math.max(1, parseInt(req.query.page, 10) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(req.query.limit, 10) || 20));
  const filter = {};

  if (req.query.status) {
    filter.status = req.query.status;
  }

  const total = await Report.countDocuments(filter);
  const reports = await Report.find(filter)
    .populate({
      path: 'post',
      select: 'content user',
      populate: {
        path: 'user',
        select: 'name email role avatar bio faculty level interests blocked createdAt updatedAt',
        populate: { path: 'faculty', select: 'name slug image location' },
      },
    })
    .populate({
      path: 'user',
      select: 'name email role avatar bio faculty level interests blocked createdAt updatedAt',
      populate: { path: 'faculty', select: 'name slug image location' },
    })
    .populate({
      path: 'reportedBy',
      select: 'name email role avatar bio faculty level interests blocked createdAt updatedAt',
      populate: { path: 'faculty', select: 'name slug image location' },
    })
    .sort({ createdAt: -1 })
    .skip((page - 1) * limit)
    .limit(limit)
    .lean();

  res.json({
    success: true,
    reports: reports.map((report) => serializeReport(report)),
    pagination: {
      page,
      limit,
      total,
      hasMore: page * limit < total,
    },
  });
});

router.put('/reports/:id', auth, async (req, res) => {
  ensureAdmin(req);

  const status = req.body.status || 'resolved';
  const report = await Report.findById(req.params.id);
  if (!report) {
    throw createHttpError(404, 'Report introuvable', 'REPORT_NOT_FOUND');
  }

  report.status = status;
  await report.save();

  res.json({
    success: true,
    message: 'Report mis a jour',
    report: {
      _id: report._id.toString(),
      status: report.status,
    },
  });
});

router.delete('/posts/:id', auth, async (req, res) => {
  ensureAdmin(req);

  const deletedPost = await Post.findByIdAndDelete(req.params.id);
  if (!deletedPost) {
    throw createHttpError(404, 'Post introuvable', 'POST_NOT_FOUND');
  }

  await Report.deleteMany({ post: req.params.id });

  res.json({
    success: true,
    message: 'Post supprime',
  });
});

router.delete('/users/:id', auth, async (req, res) => {
  ensureAdmin(req);

  const deletedUser = await User.findByIdAndDelete(req.params.id);
  if (!deletedUser) {
    throw createHttpError(404, 'Utilisateur introuvable', 'USER_NOT_FOUND');
  }

  res.json({
    success: true,
    message: 'Utilisateur supprime',
  });
});

module.exports = router;
