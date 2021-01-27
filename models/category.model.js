module.exports = (sequelize, Sequelize) => {
  const Category = sequelize.define('category', {
    name: {
      type: Sequelize.STRING,
      allowNull: false,
      unique: true,
    },
  });

  return Category
};