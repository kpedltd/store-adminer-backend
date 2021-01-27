exports.protected = function (req, res) {
  res.json({ msg: req.user.role });
};