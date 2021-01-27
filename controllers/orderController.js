const db = require('../models');
const sequelize = db.sequelize;
const Order = db.order;
const Status = require('../models/status');
const createError = require('http-errors');

exports.createOrder = async (req, res) => {
  const goods = req.body;
  if (!(goods instanceof Array)) {
    throw createError.BadRequest();
  }

  const items = [];
  for (let i = 0; i < goods.length; i++) {
    const item = goods[i];
    items.push([item.id, item.amount]);
  }

  await sequelize.query(
    'CALL WriteOrder (:userId, VARIADIC ARRAY[:items]::GOOD[])',
    {
      replacements: { userId: req.user.id, items: items, }
    });
  

  res.json({ msg: 'Order successfully created.' });
};

exports.acceptOrder = async (req, res) => {
  const { orderId } = req.query;
  const order = await Order.findOne({ where: { id: orderId } });
  if (!order) {
    throw createError(404, 'Order not found.');
  }
  if (order.status !== Status.PROCESSING) {
    throw createError(400, 'You can\'t accept the order.');
  }
  order.status = Status.ACCEPTED;
  await order.save();

  res.json({ msg: 'Order successfully accepted' });
};

exports.rejectOrder = async (req, res) => {
  const { orderId } = req.query;
  const order = await Order.findOne({ where: { id: orderId } });
  if (!order) {
    throw createError(404, 'Order not found.');
  }
  if (order.status !== Status.PROCESSING) {
    throw createError(400, 'You can\'t reject the order.');
  }
  order.status = Status.REJECTED;
  await order.save();

  res.json({ msg: 'Order successfully accepted' });
};

exports.sendOrder = async (req, res) => {
  const { orderId } = req.query;
  const order = await Order.findOne({ where: { id: orderId } });
  if (!order) {
    throw createError(404, 'Order not found.');
  }
  if (order.status !== Status.PROCESSING) {
    throw createError(400, 'You can\'t send the order.');
  }
  order.status = Status.IN_TRANSIT;
  await order.save();

  res.json({ msg: 'Order successfully accepted' });
};

exports.markOrderArrived = async (req, res) => {
  const { orderId } = req.query;
  const order = await Order.findOne({ where: { id: orderId } });
  if (!order) {
    throw createError(404, 'Order not found.');
  }
  if (order.status !== Status.IN_TRANSIT) {
    throw createError(400, 'You can\'t mark order as arrived the order.');
  }
  order.status = Status.ARRIVED;
  await order.save();

  res.json({ msg: 'Order successfully accepted' });
};