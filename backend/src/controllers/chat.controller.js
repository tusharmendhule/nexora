import { Conversation } from "../models/Conversation.js";
import { Message } from "../models/Message.js";
import { User } from "../models/User.js";

/** List the current user's conversations with unread counts. */
export async function listConversations(req, res, next) {
  try {
    const conversations = await Conversation.find({
      participants: req.user._id,
    })
      .sort({ lastMessageAt: -1 })
      .limit(50)
      .populate("participants", "name avatar username trustLabel trustScore isVerified")
      .lean();

    const data = [];
    for (const convo of conversations) {
      const messages = await Message.find({ conversation: convo._id })
        .sort({ createdAt: -1 })
        .limit(1)
        .lean();
      const unread = await Message.countDocuments({
        conversation: convo._id,
        sender: { $ne: req.user._id },
        isRead: false,
      });
      const peer = convo.participants.find(
        (p) => p._id.toString() !== req.user._id.toString(),
      );
      const last = messages[0];
      data.push({
        id: convo._id.toString(),
        participant: peer ?? convo.participants[0],
        lastMessage: last
          ? {
              id: last._id.toString(),
              senderId: last.sender.toString(),
              text: last.text,
              createdAt: last.createdAt,
            }
          : null,
        unreadCount: unread,
      });
    }
    res.json({ data });
  } catch (err) {
    next(err);
  }
}

/** Find-or-create a conversation with another user. */
export async function startConversation(req, res, next) {
  try {
    const { userId } = req.body;
    if (!userId) return res.status(400).json({ error: "userId required" });
    const other = await User.findById(userId);
    if (!other) return res.status(404).json({ error: "User not found" });

    let convo = await Conversation.findOne({
      participants: { $all: [req.user._id, other._id] },
    });
    if (!convo) {
      convo = await Conversation.create({
        participants: [req.user._id, other._id],
      });
    }
    res.status(201).json({ conversationId: convo._id.toString() });
  } catch (err) {
    next(err);
  }
}

/** Message history for a conversation. */
export async function getMessages(req, res, next) {
  try {
    const convo = await Conversation.findById(req.params.id);
    if (!convo || !convo.participants.some((p) => p.toString() === req.user._id.toString())) {
      return res.status(404).json({ error: "Conversation not found" });
    }
    const messages = await Message.find({ conversation: convo._id })
      .sort({ createdAt: 1 })
      .limit(200)
      .lean();

    // Mark received messages as read.
    await Message.updateMany(
      { conversation: convo._id, sender: { $ne: req.user._id }, isRead: false },
      { isRead: true },
    );

    res.json({
      data: messages.map((m) => ({
        id: m._id.toString(),
        senderId: m.sender.toString(),
        text: m.text,
        createdAt: m.createdAt,
        isRead: m.isRead,
      })),
    });
  } catch (err) {
    next(err);
  }
}

/** Send a message in a conversation. */
export async function sendMessage(req, res, next) {
  try {
    const { text } = req.body;
    if (!text || !text.trim()) {
      return res.status(400).json({ error: "message text required" });
    }
    const convo = await Conversation.findById(req.params.id);
    if (!convo || !convo.participants.some((p) => p.toString() === req.user._id.toString())) {
      return res.status(404).json({ error: "Conversation not found" });
    }

    const message = await Message.create({
      conversation: convo._id,
      sender: req.user._id,
      text: text.trim().slice(0, 2000),
    });
    await Conversation.findByIdAndUpdate(convo._id, {
      lastMessageAt: new Date(),
    });
    res.status(201).json({
      message: {
        id: message._id.toString(),
        senderId: message.sender.toString(),
        text: message.text,
        createdAt: message.createdAt,
        isRead: message.isRead,
      },
    });
  } catch (err) {
    next(err);
  }
}
