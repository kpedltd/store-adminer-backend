module.exports = (sequelize, Sequelize) => {
  const Good = sequelize.define('good', {
    name: {
      type: Sequelize.STRING,
      allowNull: false,
    },
    manufacturedAt: {
      type: Sequelize.DATE,
      allowNull: false,
    },
    partNumber: {
      type: Sequelize.INTEGER,
      allowNull: false,
      unique: true,
    },
    amount: {
      type: Sequelize.INTEGER,
      allowNull: false,
      defaultValue: 0,
    },
    categoryId: {
      type: Sequelize.INTEGER,
      allowNull: false,
    },
    description: {
      type: Sequelize.STRING,
    },
  });

  Good.associate = function (db) {
    db.category.hasMany(Good, { foreignKey: 'categoryId' });
  };

  return Good
};