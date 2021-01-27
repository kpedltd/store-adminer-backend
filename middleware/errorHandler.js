const HttpErrors = require('http-errors');

module.exports = function (err, req, res, next) {
    if (err instanceof HttpErrors.HttpError) {
        res.status(err.status).json({
            msg: err.message,
        });
    } else {
        res.status(500);
        if (process.env.NODE_ENV === 'development') {
            res.json({
                msg: err.message,
                stacktrace: err.stacktrace,
            });
        } else {
            res.json({
                msg: 'Something broke',
            });
        }
    }
};