const toId = (value) => {
  if (!value) {
    return null;
  }

  if (typeof value === 'string') {
    return value;
  }

  if (value._id) {
    return value._id.toString();
  }

  return value.toString();
};

const serializeFaculty = (faculty) => {
  if (!faculty) {
    return null;
  }

  if (typeof faculty === 'string') {
    return { _id: faculty };
  }

  return {
    _id: toId(faculty),
    name: faculty.name,
    slug: faculty.slug,
    image: faculty.image || '',
    location: faculty.location || '',
  };
};

const serializeUserSummary = (user) => {
  if (!user) {
    return null;
  }

  return {
    _id: toId(user),
    name: user.name || '',
    email: user.email,
    role: user.role,
    avatar: user.avatar || '',
    bio: user.bio || '',
    faculty: serializeFaculty(user.faculty),
    level: user.level,
    interests: Array.isArray(user.interests) ? user.interests : [],
    blocked: Boolean(user.blocked),
    createdAt: user.createdAt,
    updatedAt: user.updatedAt,
  };
};

const serializeUserProfile = (user, extra = {}) => {
  if (!user) {
    return null;
  }

  return {
    ...serializeUserSummary(user),
    followers: Array.isArray(user.followers)
      ? user.followers.map(serializeUserSummary).filter(Boolean)
      : [],
    following: Array.isArray(user.following)
      ? user.following.map(serializeUserSummary).filter(Boolean)
      : [],
    followersCount:
      extra.followersCount ?? (Array.isArray(user.followers) ? user.followers.length : 0),
    followingCount:
      extra.followingCount ?? (Array.isArray(user.following) ? user.following.length : 0),
    postsCount: extra.postsCount ?? user.postsCount ?? 0,
    isFollowing: Boolean(extra.isFollowing),
  };
};

const serializeComment = (comment) => {
  if (!comment) {
    return null;
  }

  return {
    _id: toId(comment),
    user: serializeUserSummary(comment.user),
    post: toId(comment.post),
    content: comment.content || '',
    likesCount: Array.isArray(comment.likes) ? comment.likes.length : 0,
    createdAt: comment.createdAt,
    updatedAt: comment.updatedAt,
  };
};

const serializeAttachment = (attachment) => {
  if (!attachment) {
    return null;
  }

  return {
    url: attachment.url || '',
    fileName: attachment.fileName || attachment.name || '',
    mimeType: attachment.mimeType || 'application/octet-stream',
    size: attachment.size || 0,
    kind: attachment.kind || 'document',
  };
};

const pickPrimaryMedia = (media) => {
  if (!media) {
    return null;
  }

  if (Array.isArray(media)) {
    return media[0] || null;
  }

  return media;
};

const serializePost = (post, currentUserId) => {
  if (!post) {
    return null;
  }

  const likes = Array.isArray(post.likes) ? post.likes.map(toId) : [];
  const comments = Array.isArray(post.comments) ? post.comments : [];

  return {
    _id: toId(post),
    user: serializeUserSummary(post.user),
    content: post.content || '',
    media: pickPrimaryMedia(post.media),
    mediaItems: Array.isArray(post.media)
      ? post.media
      : post.media
        ? [post.media]
        : [],
    hashtags: Array.isArray(post.hashtags) ? post.hashtags : [],
    mentions: Array.isArray(post.mentions)
      ? post.mentions.map(serializeUserSummary).filter(Boolean)
      : [],
    likesCount: likes.length,
    commentsCount: comments.length,
    isLiked: currentUserId ? likes.includes(currentUserId.toString()) : false,
    comments: comments
      .map((comment) => serializeComment(comment))
      .filter(Boolean),
    group: post.group ? toId(post.group) : null,
    faculty: serializeFaculty(post.faculty),
    createdAt: post.createdAt,
    updatedAt: post.updatedAt,
  };
};

const serializeMessage = (message) => {
  if (!message) {
    return null;
  }

  const attachments = Array.isArray(message.attachments)
    ? message.attachments.map((attachment) => serializeAttachment(attachment)).filter(Boolean)
    : [];

  return {
    _id: toId(message),
    sender: serializeUserSummary(message.sender),
    receiver: serializeUserSummary(message.receiver),
    content: message.content || '',
    attachments,
    hasAttachments: attachments.length > 0,
    read: Boolean(message.read),
    createdAt: message.createdAt,
    updatedAt: message.updatedAt,
  };
};

const serializeStory = (story, currentUserId) => {
  if (!story) {
    return null;
  }

  const viewerIds = Array.isArray(story.viewers)
    ? story.viewers.map((viewer) => toId(viewer)).filter(Boolean)
    : [];

  return {
    _id: toId(story),
    user: serializeUserSummary(story.user),
    mediaUrl: story.mediaUrl || '',
    mediaType: story.mediaType || '',
    caption: story.caption || '',
    viewersCount: viewerIds.length,
    hasViewed: currentUserId ? viewerIds.includes(currentUserId.toString()) : false,
    createdAt: story.createdAt,
    expiresAt: story.expiresAt,
  };
};

const serializeNotification = (notification) => {
  if (!notification) {
    return null;
  }

  return {
    _id: toId(notification),
    user: toId(notification.user),
    type: notification.type,
    content: notification.content || '',
    referenceId: toId(notification.referenceId),
    read: Boolean(notification.read),
    createdAt: notification.createdAt,
    updatedAt: notification.updatedAt,
  };
};

const serializeReport = (report) => {
  if (!report) {
    return null;
  }

  return {
    _id: toId(report),
    reason: report.reason,
    description: report.description || '',
    status: report.status,
    action: report.action || 'none',
    post: report.post
      ? {
          _id: toId(report.post),
          content: report.post.content || '',
          user: serializeUserSummary(report.post.user),
        }
      : null,
    user: serializeUserSummary(report.user),
    comment: report.comment ? toId(report.comment) : null,
    reportedBy: serializeUserSummary(report.reportedBy),
    createdAt: report.createdAt,
    updatedAt: report.updatedAt,
  };
};

module.exports = {
  serializeComment,
  serializeFaculty,
  serializeMessage,
  serializeNotification,
  serializePost,
  serializeReport,
  serializeStory,
  serializeUserProfile,
  serializeUserSummary,
  serializeAttachment,
  toId,
};
