import { Conversation } from "../models/Conversation.js";
import { Message } from "../models/Message.js";
import { User } from "../models/User.js";
import { Block } from "../models/Block.js";
import { emitToUser } from "../services/socket.service.js";
import { media } from "../services/cloudinary.service.js";

/** List the current user's conversations with unread counts (batched). */
export async function listConversations(req, res, next) {
  try {
    const conversations = await Conversation.find({
      participants: req.user._id,
    })
      .sort({ lastMessageAt: -1 })
      .limit(50)
      .populate("participants", "name avatar username trustLabel trustScore isVerified")
      .lean();

    const convoIds = conversations.map((c) => c._id);
    if (convoIds.length === 0) return res.json({ data: [] });

    // Batch 1: the latest message per conversation.
    const lastMessages = await Message.aggregate([
      { $match: { conversation: { $in: convoIds } } },
      { $sort: { createdAt: -1 } },
      {
        $group: {
          _id: "$conversation",
          id: { $first: "$_id" },
          sender: { $first: "$sender" },
          text: { $first: "$text" },
          type: { $first: "$type" },
          createdAt: { $first: "$createdAt" },
        },
      },
    ]);
    const lastByConvo = new Map(lastMessages.map((m) => [m._id.toString(), m]));

    // Batch 2: unread counts for all conversations at once.
    const unreadRows = await Message.aggregate([
      {
        $match: {
          conversation: { $in: convoIds },
          sender: { $ne: req.user._id },
          isRead: false,
        },
      },
      { $group: { _id: "$conversation", count: { $sum: 1 } } },
    ]);
    const unreadByConvo = new Map(
      unreadRows.map((r) => [r._id.toString(), r.count]),
    );

    const data = conversations.map((convo) => {
      const peer = convo.participants.find(
        (p) => p._id.toString() !== req.user._id.toString(),
      );
      const last = lastByConvo.get(convo._id.toString());
      return {
        id: convo._id.toString(),
        participant: peer ?? convo.participants[0],
        lastMessage: last
          ? {
              id: last.id.toString(),
              senderId: last.sender.toString(),
              text: last.text,
              type: last.type ?? "text",
              createdAt: last.createdAt,
            }
          : null,
        unreadCount: unreadByConvo.get(convo._id.toString()) ?? 0,
      };
    });
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
    const isNew = !convo;
    if (!convo) {
      convo = await Conversation.create({
        participants: [req.user._id, other._id],
      });
    }
    const conversationId = convo._id.toString();
    if (isNew) {
      // Real-time: let the peer know a fresh conversation exists.
      emitToUser(other._id, "chat:conversation", { conversationId });
    }
    res.status(201).json({ conversationId });
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
        type: m.type ?? "text",
        createdAt: m.createdAt,
        isRead: m.isRead,
      })),
    });
  } catch (err) {
    next(err);
  }
}

/** Send a message in a conversation (text, or an uploaded image). */
export async function sendMessage(req, res, next) {
  try {
    const convo = await Conversation.findById(req.params.id);
    if (!convo || !convo.participants.some((p) => p.toString() === req.user._id.toString())) {
      return res.status(404).json({ error: "Conversation not found" });
    }

    // Blocked peers cannot send you messages.
    const peer = convo.participants.find(
      (p) => p.toString() !== req.user._id.toString(),
    );
    if (peer) {
      const blocked = await Block.exists({
        $or: [
          { blocker: req.user._id, blocked: peer },
          { blocker: peer, blocked: req.user._id },
        ],
      });
      if (blocked) {
        return res.status(403).json({ error: "Messaging is blocked between these accounts" });
      }
    }

    const { text } = req.body ?? {};
    let type = "text";
    let content = (text ?? "").trim().slice(0, 2000);

    // Optional image upload (multipart `image` field).
    if (req.file) {
      const uploaded = await media.upload({
        buffer: req.file.buffer,
        folder: "nexora/chat",
      });
      type = "image";
      content = uploaded.url;
    }
    if (!content) {
      return res.status(400).json({ error: "message text or image required" });
    }

    const message = await Message.create({
      conversation: convo._id,
      sender: req.user._id,
      text: content,
      type,
    });
    await Conversation.findByIdAndUpdate(convo._id, {
      lastMessageAt: new Date(),
    });

    const payload = {
      id: message._id.toString(),
      conversationId: convo._id.toString(),
      senderId: message.sender.toString(),
      text: message.text,
      type: message.type,
      createdAt: message.createdAt,
      isRead: message.isRead,
    };

    // Real-time: deliver instantly to every other participant.
    const others = convo.participants.filter(
      (p) => p.toString() !== req.user._id.toString(),
    );
    for (const other of others) {
      emitToUser(other, "chat:message", payload);
    }
    res.status(201).json({ message: payload });
  } catch (err) {
    next(err);
  }
}
