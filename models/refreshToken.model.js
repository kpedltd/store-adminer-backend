module.exports = (sequelize, Sequelize) => {
  const RefreshToken = sequelize.define('refreshToken', {
    userId: {
      type: Sequelize.INTEGER,
      allowNull: false,
    },
    token: {
      type: Sequelize.STRING,
      allowNull: false,
    },
    exp: {
      type: Sequelize.DATE,
      allowNull: false,
    },
    createdByIp: {
      type: Sequelize.STRING,
      allowNull: false,
    },
    revoked: {
      type: Sequelize.DATE,
    },
    revokedByIp: {
      type: Sequelize.STRING,
    },
    replacedByToken: {
      type: Sequelize.STRING,
    },
  });

  RefreshToken.prototype.isExprired = function () {
    return Date.now() >= this.exp;
  };

  RefreshToken.prototype.isActive = function () {
    return !this.revoked && !this.isExprired()
  };

  RefreshToken.associate = function (db) {
    db.user.hasMany(RefreshToken, { foreignKey: 'userId' });
  };

  return RefreshToken;
};