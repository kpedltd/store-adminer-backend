//const bCrypt = require('bcrypt');

module.exports = (sequelize, Sequelize) => {
  const User = sequelize.define('user', {
    login: {
      type: Sequelize.STRING,
      allowNull: false,
      unique: true,
    },
    lastname: {
      type: Sequelize.STRING,
      allowNull: false,
    },
    firstname: {
      type: Sequelize.STRING,
      allowNull: false,
    },
    isBlocked: {
      type: Sequelize.BOOLEAN,
      allowNull: false,
      defaultValue: false,
    },
    lastLogin: {
      type: Sequelize.DATE,
    },
    lastLoginIp: {
      type: Sequelize.STRING,
    },
    passwordHash: {
      type: Sequelize.STRING,
      allowNull: false,
    },
    role: {
      type: Sequelize.STRING,
      allowNull: false,
    },
  }, {
    setterMethods: {
      password: function (value) {
        this.passwordHash = value;//bCrypt.hashSync(value, bCrypt.genSaltSync(8));
      }
    }
  });

  User.prototype.comparePassword = function (password) {
    return bCrypt.compareSync(password, this.passwordHash);
  };

  User.prototype.ownsRefreshToken = function (token) {
    return this.id == token.userId;
  };

  return User;
};