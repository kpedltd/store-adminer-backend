const db = require('../models')
const roleProvider = require('../models/role');
const statusProvider = require('../models/status')


function randomDate(date1, date2){
    function randomValueBetween(min, max) {
      return Math.random() * (max - min) + min;
    }
    var date1 = date1 || '01-01-1970'
    var date2 = date2 || new Date().toLocaleDateString()
    date1 = new Date(date1).getTime()
    date2 = new Date(date2).getTime()
    if( date1>date2){
        return new Date(randomValueBetween(date2,date1))
    } else{
        return new Date(randomValueBetween(date1, date2)) 

    }
}

const dates_constraint = [
    new Date("2020-1-1"), new Date("2021-2-1")
];

const randomDateClojure = (() => {
    return () => {
        return randomDate(
            dates_constraint[0],
            dates_constraint[1]);
    }
})();


const UsersCreate = async () =>
{
    console.debug("UsersCreate");
    try
    {
        await db.user.create({
            login: "admin",
            lastname: "Петров",
            firstname: "Петр",
            passwordHash: "qwerty",
            role: roleProvider.Admin
        });

        await db.user.create({
            login: "igor",
            lastname: "Кузнецов",
            firstname: "Игорь",
            passwordHash: "qwerty",
            role: roleProvider.User
        });

        await db.user.create({
            login: "andrey",
            lastname: "Максимов",
            firstname: "Андрей",
            passwordHash: "qwerty",
            role: roleProvider.User
        });

        await db.user.create({
            login: "diman",
            lastname: "Федеров",
            firstname: "Дима",
            passwordHash: "qwerty",
            role: roleProvider.User
        });
    }
    catch(err)
    {
        console.log(err.message);
    }
};

const CategoryCreate = async () => 
{
    console.debug("CategoryCreate");
    try
    {
        await db.category.create({
            name: "Фрукты"
        });

        await db.category.create({
            name: "Техника"
        });
    }
    catch(err)
    {
        console.log(err.message);
    }
}

const GoodsCreate = async () =>
{
    console.debug("GoodsCreate");
    try
    {
        await db.good.create({
            name: "Яблоки",
            manufacturedAt: randomDateClojure(),
            partNumber: 1,
            amount: 1254,
            categoryId: 1
        });

        await db.good.create({
            name: "Груши",
            manufacturedAt: randomDateClojure(),
            partNumber: 2,
            amount: 5322,
            categoryId: 1
        });

        await db.good.create({
            name: "Бананы",
            manufacturedAt: randomDateClojure(),
            partNumber: 3,
            amount: 665,
            categoryId: 1
        });

        await db.good.create({
            name: "Телевизор",
            manufacturedAt: randomDateClojure(),
            partNumber: 4,
            amount: 65,
            categoryId: 1
        });

        await db.good.create({
            name: "Принтер",
            manufacturedAt: randomDateClojure(),
            partNumber: 5,
            amount: 11,
            categoryId: 1
        });
    }
    catch(err)
    {
        console.log(err.message);
    }
};

const PriceCreate = async () =>
{
    console.debug("PriceCreate");
    try
    {
        await db.price.create({
            goodId: 1,
            price: 65
        });

        await db.price.create({
            goodId: 1,
            price: 80
        });

        await db.price.create({
            goodId: 1,
            price: 70
        });

        await db.price.create({
            goodId: 2,
            price: 99
        });

        await db.price.create({
            goodId: 2,
            price: 155
        });

        await db.price.create({
            goodId: 3,
            price: 144
        });

        await db.price.create({
            goodId: 3,
            price: 130
        });

        await db.price.create({
            goodId: 4,
            price: 25000
        });

        await db.price.create({
            goodId: 4,
            price: 25999
        });

        await db.price.create({
            goodId: 4,
            price: 30999
        });

        await db.price.create({
            goodId: 5,
            price: 2500
        });

        await db.price.create({
            goodId: 5,
            price: 4000
        });
    }
    catch(err)
    {
        console.log(err.message);
    }
};

const OrderCreate = async () => 
{
    console.debug("OrderCreate");
    try
    {
        await db.order.create({
            userId: 2,
            status: statusProvider.PROCESSING
        });

        await db.order.create({
            userId: 3,
            status: statusProvider.REJECTED
        });

        await db.order.create({
            userId: 4,
            status: statusProvider.ACCEPTED
        });
    }
    catch(err)
    {
        console.log(err.message);
    }
}

const OrderGoodCrate = async () => 
{
    console.debug("OrderGoodCrate");
    try
    {
        await db.orderGood.create({
            orderId: 1,
            goodId: 1,
            amount: 100,
            priceId: 3
        });

        await db.orderGood.create({
            orderId: 2,
            goodId: 2,
            amount: 500,
            priceId: 1
        });

        await db.orderGood.create({
            orderId: 3,
            goodId: 4,
            amount: 10,
            priceId: 2
        });
    }
    catch(err)
    {
        console.log(err.message);
    }
}

module.exports = [
    UsersCreate,
    CategoryCreate,
    GoodsCreate,
    PriceCreate,
    OrderCreate,
    OrderGoodCrate
];