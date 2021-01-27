const express = require('express');
const app = express();
const bodyParser = require('body-parser');
const cookieParser = require('cookie-parser');
const db = require('./models');
const sequelize = db.sequelize;

process.env['NODE_ENV'] = 'development';

const auth = require('./middleware/auth')();
const authRoute = require('./routes/authRoute');
const userRoute = require('./routes/userRoute');
const goodRoute = require('./routes/goodRoute');
const orderRoute = require('./routes/orderRoute');
const databaseRoute = require('./routes/databaseRoute');
const errorHandler = require('./middleware/errorHandler');

app.use(bodyParser.json());
app.use(cookieParser());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(auth.initialize());

app.use(authRoute);
app.use(userRoute);
app.use(goodRoute);
app.use(orderRoute);
app.use(databaseRoute);

app.use(errorHandler);

sequelize.authenticate().
  then(() => {
    sequelize
      .sync({ force: false })
      .then(() => {
        app.listen(3000, function () {
          console.log('Server is running on port 3000');
        });
      })
      .catch(err => {
        console.error(err);
      });
  })
  .catch((err) => {
    console.error(err);
  });