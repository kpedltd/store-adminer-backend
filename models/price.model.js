module.exports = (sequelize, Sequelize) => {
  const Price = sequelize.define('price', {
    goodId: {
      type: Sequelize.INTEGER,
      allowNull: false,
    },
    price: {
      type: Sequelize.DECIMAL(10, 2),
      allowNull: false,
    },
  });

  Price.associate = function (db) {
    db.good.hasMany(Price, { as: 'history', foreignKey: 'goodId' });
    Price.belongsTo(db.good, { foreignKey: 'goodId' });
  };

  return Price;
};