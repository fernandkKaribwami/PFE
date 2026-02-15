const mongoose = require('mongoose');
const Schema = mongoose.Schema;
const UserSchema = new Schema({
  nom: String,
  prenom: String,
  email: { type: String, unique: true },
  passwordHash: String,
  role: { type: String, enum: ['student', 'teacher', 'admin'], default: 'student' },
  faculty: { type: Schema.Types.ObjectId, ref: 'Faculty' },
  filiere: String,
  niveau: String,
  bio: { type: String, default: '' },
  avatarUrl: { type: String, default: null },
  interests: [String],
  isVerified: { type: Boolean, default: false },
  verificationCode: { type: String, default: null },
  resetPasswordToken: { type: String, default: null },
  resetPasswordExpires: { type: Date, default: null },
  followers: [{ type: Schema.Types.ObjectId, ref: 'User' }],
  following: [{ type: Schema.Types.ObjectId, ref: 'User' }],
  blocked: [{ type: Schema.Types.ObjectId, ref: 'User' }],
  followersCount: { type: Number, default: 0 },
  followingCount: { type: Number, default: 0 },
  postsCount: { type: Number, default: 0 }
},{ timestamps: true });
module.exports = mongoose.model('User', UserSchema);