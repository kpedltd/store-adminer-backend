const db = require('../models');
const sequelize = db.sequelize;
const Category = db.category;
const Good = db.good;
const Price = db.price;
const createError = require('http-errors');

exports.createCategory = async (req, res) => {
  console.log('Category successfuly created.')
  res.json(await Category.create(req.body));
};

exports.getCategory = async (req, res) => {
  const id = req.query.id;

  if (id === undefined) {
    res.json(await Category.findAll());
  } else {
    res.json(await Category.findOne({ where: { id } }));
  }
};

exports.removeCategories = async (req, res) => {
  const categories = req.body;
  if (!(categories instanceof Array)) {
    throw createError.BadRequest();
  }

  const itemsToRemove = []
  for (let i = 0; i < categories.length; i++) {
    const item = categories[i];
    itemsToRemove.push(item.id);
  }

  await sequelize.query(
    'CALL RemoveCategories (VARIADIC ARRAY[:items]::INTEGER[])',
    {
      replacements: { items: itemsToRemove, }
    });

  console.log(itemsToRemove.length + ' categories successfuly removed.');
  res.json({ msg: itemsToRemove.length + ' categories successfuly removed.' });
};

exports.updateCategory = async (req, res) => {
  const item = req.body;

  const category = await Category.findOne({
    where: { id : item.id }
  });

  if (!category) {
    throw createError(404, 'Category not found.')
  }

  category.name = item.name;

  await category.save();

  console.log('Category successfuly updated.');
  res.json({ msg: 'Category successfuly updated.' });
};

exports.createGood = async (req, res) => {
  const price = req.body.price;
  if (price === undefined) {
    throw createError.BadRequest();
  }
  const addedGood = await Good.create(req.body);
  await Price.create({ price: price, goodId: addedGood.id });
  addedGood.dataValues.price = price

  console.log('Good successfuly created.');
  res.json(addedGood.dataValues);
};

exports.getGood = async (req, res) => {
  const result = await sequelize.query('SELECT * FROM "goodsWithPrice"');
  res.json(result[0]);
};

exports.removeGoods = async (req, res) => {
  const goods = req.body;
  if (!(goods instanceof Array)) {
    throw createError.BadRequest();
  }

  const items = []
  for (let i = 0; i < goods.length; i++) {
    const item = goods[i];
    items.push(item.id);
  }

  await sequelize.query(
    'CALL RemoveGoods (VARIADIC ARRAY[:items]::INTEGER[])',
    {
      replacements: { items: items, }
    });

  console.log(items.length + ' goods successfuly removed.');
  res.json({ msg: items.length + ' goods successfuly removed.' });
};

exports.updateGood = async (req, res) => {
  const item = req.body;

  const good = await Good.findOne({
    where: { id: item.id }
  });

  if (!good) {
    throw createError(404, 'Good not found.')
  }

  good.name = item.name;
  good.partNumber = item.partNumber;
  good.manufacturedAt = item.manufacturedAt;
  good.categoryId = item.categoryId;
  good.description = item.description;

  await good.save();

  const priceRecord = await Price.findOne({
    where: { goodId: good.id },
    order: [
      ['createdAt', 'DESC']
    ],
    limit: 1,
  })

  if (priceRecord.dataValues.price != item.price) {
    await Price.create({ price: item.price, goodId: item.id });
  }

  console.log('Good successfuly updated.');
  res.json({ msg: 'Good successfuly updated.' });
};

exports.getPriceHistory = async (req, res) => {
  res.json(await Price.findAll({ where: { goodId: req.query.goodId } }));
}