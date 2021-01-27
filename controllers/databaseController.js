const db = require('../models');
const sequelize = db.sequelize;
const async = require('async')

const strategies = require('../data_constuction')

exports.fillDatabase = async (req, res) => {
    async.series(strategies);

    await res.json({
        success: true
    });
};

exports.dropDatabase = async (req, res) => {
    sequelize.sync({force: true});
    res.json({
        success: true
    });
}