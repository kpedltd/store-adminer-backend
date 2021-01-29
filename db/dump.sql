--
-- PostgreSQL database dump
--

-- Dumped from database version 12.5
-- Dumped by pg_dump version 12.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: good; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.good AS (
	id integer,
	amount integer
);


ALTER TYPE public.good OWNER TO postgres;

--
-- Name: checkavailability(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.checkavailability() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  goodId INTEGER;
  available INTEGER;
  desired INTEGER;
BEGIN

  IF OLD.status = 'Processing' AND NEW.status = 'Accepted' THEN

    FOR goodId, available, desired IN
      SELECT "goods"."id", "goods".amount, "order_goods".amount FROM "order_goods" 
      JOIN "goods" ON "goods".id = "goodId" 
      WHERE "orderId" = NEW."id"
    LOOP

      IF desired > available THEN
        RAISE EXCEPTION 'Not enough goods.';
      END IF;

      UPDATE "goods" SET "amount" = available - desired WHERE "id" = goodId;

    END LOOP;
  
  END IF;

  RETURN new;
END;
$$;


ALTER FUNCTION public.checkavailability() OWNER TO postgres;

--
-- Name: getgoodstatistic(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.getgoodstatistic(idgood integer) RETURNS TABLE(id integer, name character varying, partnumber integer, amount bigint, price numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN

  RETURN QUERY SELECT
    "goods"."id",
    "goods"."name",
    "goods"."partNumber",
    SUM("order_goods"."amount") as amount,
    SUM("prices"."price" * "order_goods"."amount") AS price
  FROM 
    "order_goods"
  JOIN
    "goods"
  ON
    "goods"."id" = "order_goods"."goodId"
  JOIN
    "prices"
  ON
    "prices"."id" = "priceId"
  JOIN 
    "orders" 
  ON 
    "orders"."id" = "orderId"
  WHERE 
    "status" = 'Arrived'
  GROUP BY "goods"."id";

END;
$$;


ALTER FUNCTION public.getgoodstatistic(idgood integer) OWNER TO postgres;

--
-- Name: removecategories(integer[]); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.removecategories(VARIADIC ids integer[])
    LANGUAGE plpgsql
    AS $$
BEGIN
  
  DELETE FROM "categories" WHERE "id" = ANY(ids);
  
END;
$$;


ALTER PROCEDURE public.removecategories(VARIADIC ids integer[]) OWNER TO postgres;

--
-- Name: removegoods(integer[]); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.removegoods(VARIADIC ids integer[])
    LANGUAGE plpgsql
    AS $$
BEGIN
  
  DELETE FROM "goods" WHERE "id" = ANY(ids);
  
END;
$$;


ALTER PROCEDURE public.removegoods(VARIADIC ids integer[]) OWNER TO postgres;

--
-- Name: writeorder(integer, public.good[]); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.writeorder(userid integer, VARIADIC goods public.good[])
    LANGUAGE plpgsql
    AS $$
DECLARE
  orderId INTEGER;
  priceId INTEGER;
  available INTEGER;
  good GOOD;
BEGIN
  INSERT INTO 
    "orders" ("userId", "createdAt", "updatedAt")
  VALUES 
    (userId, NOW(), NOW()) RETURNING id INTO orderId;

  FOREACH good in ARRAY goods LOOP

    SELECT DISTINCT ON ("goodId") "id" FROM "prices" WHERE "goodId" = good.id 
    ORDER BY "goodId", "createdAt" DESC 
    INTO priceId;

    SELECT "amount" FROM "goods" WHERE "id" = good.id 
    INTO available;

    if good.amount > available THEN
      RAISE EXCEPTION 'Not enough goods.';
    END IF;

    INSERT INTO
      "order_goods" ("orderId", "goodId", "amount", "priceId", "createdAt", "updatedAt")
    VALUES
      (orderId, good.id, good.amount, priceId, NOW(), NOW());

  END LOOP;
  
END;
$$;


ALTER PROCEDURE public.writeorder(userid integer, VARIADIC goods public.good[]) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categories (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);


ALTER TABLE public.categories OWNER TO postgres;

--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.categories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.categories_id_seq OWNER TO postgres;

--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.categories_id_seq OWNED BY public.categories.id;


--
-- Name: category_statistics; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.category_statistics AS
SELECT
    NULL::integer AS id,
    NULL::character varying(255) AS name,
    NULL::numeric AS amount;


ALTER TABLE public.category_statistics OWNER TO postgres;

--
-- Name: goods; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.goods (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    "manufacturedAt" timestamp with time zone NOT NULL,
    "partNumber" integer NOT NULL,
    amount integer DEFAULT 0 NOT NULL,
    "categoryId" integer NOT NULL,
    description character varying(255),
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);


ALTER TABLE public.goods OWNER TO postgres;

--
-- Name: prices; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.prices (
    id integer NOT NULL,
    "goodId" integer NOT NULL,
    price numeric(10,2) NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);


ALTER TABLE public.prices OWNER TO postgres;

--
-- Name: goodsWithPrice; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public."goodsWithPrice" AS
 SELECT DISTINCT ON (prices."goodId") goods.id,
    goods.name,
    goods."manufacturedAt",
    goods."partNumber",
    goods.amount,
    goods."categoryId",
    goods.description,
    goods."createdAt",
    goods."updatedAt",
    prices.price
   FROM (public.prices
     JOIN public.goods ON ((goods.id = prices."goodId")))
  ORDER BY prices."goodId", prices."createdAt" DESC;


ALTER TABLE public."goodsWithPrice" OWNER TO postgres;

--
-- Name: order_goods; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_goods (
    "orderId" integer NOT NULL,
    "goodId" integer NOT NULL,
    amount integer NOT NULL,
    "priceId" integer NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);


ALTER TABLE public.order_goods OWNER TO postgres;

--
-- Name: goodsForOrder; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public."goodsForOrder" AS
 SELECT "goodsWithPrice".id,
    "goodsWithPrice".name,
    "goodsWithPrice"."manufacturedAt",
    "goodsWithPrice"."partNumber",
    "goodsWithPrice"."categoryId",
    "goodsWithPrice".description,
    "goodsWithPrice".price,
    order_goods.amount,
    order_goods."orderId"
   FROM (public.order_goods
     JOIN public."goodsWithPrice" ON (("goodsWithPrice".id = order_goods."goodId")));


ALTER TABLE public."goodsForOrder" OWNER TO postgres;

--
-- Name: goods_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.goods_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.goods_id_seq OWNER TO postgres;

--
-- Name: goods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.goods_id_seq OWNED BY public.goods.id;


--
-- Name: goods_statistics; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.goods_statistics AS
SELECT
    NULL::integer AS id,
    NULL::character varying(255) AS name,
    NULL::timestamp with time zone AS "manufacturedAt",
    NULL::integer AS "categoryId",
    NULL::character varying(255) AS description,
    NULL::bigint AS amount,
    NULL::numeric AS price;


ALTER TABLE public.goods_statistics OWNER TO postgres;

--
-- Name: orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.orders (
    id integer NOT NULL,
    "userId" integer NOT NULL,
    status character varying(255) DEFAULT 'Processing'::character varying NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);


ALTER TABLE public.orders OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    login character varying(255) NOT NULL,
    lastname character varying(255) NOT NULL,
    firstname character varying(255) NOT NULL,
    "isBlocked" boolean DEFAULT false NOT NULL,
    "lastLogin" timestamp with time zone,
    "lastLoginIp" character varying(255),
    "passwordHash" character varying(255) NOT NULL,
    role character varying(255) NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: ordersInfo; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public."ordersInfo" AS
 SELECT "goodsForOrder".id,
    "goodsForOrder".name,
    "goodsForOrder"."manufacturedAt",
    "goodsForOrder"."partNumber",
    "goodsForOrder"."categoryId",
    "goodsForOrder".description,
    "goodsForOrder".price,
    "goodsForOrder".amount,
    "goodsForOrder"."orderId",
    orders."userId",
    orders.status,
    orders."createdAt",
    users.login
   FROM ((public."goodsForOrder"
     JOIN public.orders ON ((orders.id = "goodsForOrder"."orderId")))
     JOIN public.users ON ((users.id = orders."userId")));


ALTER TABLE public."ordersInfo" OWNER TO postgres;

--
-- Name: orders_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.orders_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.orders_id_seq OWNER TO postgres;

--
-- Name: orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.orders_id_seq OWNED BY public.orders.id;


--
-- Name: prices_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.prices_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.prices_id_seq OWNER TO postgres;

--
-- Name: prices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.prices_id_seq OWNED BY public.prices.id;


--
-- Name: refreshTokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."refreshTokens" (
    id integer NOT NULL,
    "userId" integer NOT NULL,
    token character varying(255) NOT NULL,
    exp timestamp with time zone NOT NULL,
    "createdByIp" character varying(255) NOT NULL,
    revoked timestamp with time zone,
    "revokedByIp" character varying(255),
    "replacedByToken" character varying(255),
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);


ALTER TABLE public."refreshTokens" OWNER TO postgres;

--
-- Name: refreshTokens_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."refreshTokens_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."refreshTokens_id_seq" OWNER TO postgres;

--
-- Name: refreshTokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."refreshTokens_id_seq" OWNED BY public."refreshTokens".id;


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: categories id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories ALTER COLUMN id SET DEFAULT nextval('public.categories_id_seq'::regclass);


--
-- Name: goods id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.goods ALTER COLUMN id SET DEFAULT nextval('public.goods_id_seq'::regclass);


--
-- Name: orders id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders ALTER COLUMN id SET DEFAULT nextval('public.orders_id_seq'::regclass);


--
-- Name: prices id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prices ALTER COLUMN id SET DEFAULT nextval('public.prices_id_seq'::regclass);


--
-- Name: refreshTokens id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."refreshTokens" ALTER COLUMN id SET DEFAULT nextval('public."refreshTokens_id_seq"'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.categories (id, name, "createdAt", "updatedAt") FROM stdin;
1	Товары для дома	2021-01-28 21:30:49.815+00	2021-01-28 21:30:49.815+00
2	Спорт	2021-01-28 21:30:57.309+00	2021-01-28 21:30:57.309+00
3	Мебель	2021-01-28 21:31:05.246+00	2021-01-28 21:31:05.246+00
4	Бытовая техника	2021-01-28 21:31:19.817+00	2021-01-28 21:31:19.817+00
5	Еда	2021-01-28 21:31:36.66+00	2021-01-28 21:31:36.66+00
\.


--
-- Data for Name: goods; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.goods (id, name, "manufacturedAt", "partNumber", amount, "categoryId", description, "createdAt", "updatedAt") FROM stdin;
2	Холодильник КАМАЗ	2020-09-23 21:34:30+00	387432	30	4	Самый громкий холодильник в истории. Вам он точно понравится.	2021-01-28 21:35:42.547+00	2021-01-28 21:35:56.331+00
7	Шампунь жумайсынба	2018-07-24 21:44:02+00	378932	1	1	Легендарный шампунь выходит на российский рынок. Также, в скором времени, ожидается появление геля для душа и кондиционера ЖУМАЙСЫНБА.	2021-01-28 21:45:39.854+00	2021-01-28 21:45:39.854+00
10	Пылесос ТУРБО	2020-04-18 20:07:39+00	532657	16	4	Турбо пылесосит.	2021-01-28 23:08:27.06+00	2021-01-28 23:10:01.733+00
12	Ершик Путина	2021-01-13 23:10:03+00	382953	1	1	Настоящий ершик Лорда из замка в Геленджике	2021-01-28 23:11:03.514+00	2021-01-28 23:11:03.514+00
13	Пельмени Шибякенские 1 кг.	2021-01-28 23:15:52.924+00	325647	90	1	Лучшие пельмешьи изделия.	2021-01-28 23:16:50.233+00	2021-01-28 23:16:50.233+00
15	Перчатки борца Хабиба	2020-09-27 00:25:19+00	382993	1	2	Перчатки Хабиба, в которых он бил Конора.	2021-01-29 00:27:00.888+00	2021-01-29 00:27:00.888+00
8	Пластмасовый стул	2020-11-11 20:04:32+00	323532	54	3	Стул из пластмассы, а на нем пики точеные.	2021-01-28 23:05:33.893+00	2021-01-28 23:09:42.268+00
1	Велосипед STINGER	2020-05-20 21:33:07+00	783293	18	2	Красный спортивный велосипед бренда STINGER.	2021-01-28 21:34:15.715+00	2021-01-28 21:34:15.715+00
6	Футболный мяч	2020-06-12 18:42:43+00	273893	8	2	Кожанный футбольный мяч. Из человека.	2021-01-28 21:43:43.095+00	2021-01-28 21:44:00.559+00
18	Вантуз обычнiй	2020-11-13 00:29:46+00	389253	68	1	Вантуз хоть и необычный, но создает вакуум космический.	2021-01-29 00:30:59.4+00	2021-01-29 00:30:59.4+00
3	Кожаный диван	2019-06-20 18:36:01+00	783983	0	3	Диван из натуральной кожи.	2021-01-28 21:37:31.038+00	2021-01-28 21:41:29.827+00
19	Мохнатый веник	2021-01-29 00:31:02.792+00	293052	44	1	Веник из зарослей...	2021-01-29 00:32:20.202+00	2021-01-29 00:32:20.202+00
20	Бита GTA	2020-07-03 00:32:22+00	392529	17	2	Битва любителей  Лос Сантоса.	2021-01-29 00:33:21.166+00	2021-01-29 00:33:21.166+00
17	Телефизор Витязь	2021-01-29 00:28:18.86+00	389252	5	4	Российский телевизор с Тюменского пивоварного завада.	2021-01-29 00:29:32.531+00	2021-01-29 00:29:32.531+00
14	Детская коляска	2018-07-03 23:21:56+00	348233	20	1	Обычная детская коляска.	2021-01-28 23:23:04.868+00	2021-01-28 23:23:04.868+00
9	Кока Кола 1 л.	2019-10-10 20:05:56+00	345267	97	5	Пепси кола под видом Кока Колы	2021-01-28 23:07:26.14+00	2021-01-28 23:09:50.835+00
5	Мыло тюремное	2021-01-12 18:38:59+00	384928	94	1	Мыло прямиком из СИЗО, где сидел Навальный.	2021-01-28 21:40:11.744+00	2021-01-28 21:42:28.513+00
4	Пицца Пеперони 60 см	1994-03-18 18:37:34+00	874793	28	5	Пицца холодная. Не покупайте.	2021-01-28 21:38:49.298+00	2021-01-28 21:42:41.9+00
16	Пирог из фильма "Американский пирог"	2020-12-18 00:27:18+00	293895	3	5	Пирог по рецептам знаменитого фильма.	2021-01-29 00:28:16.288+00	2021-01-29 00:28:16.288+00
11	Леденцы черные 1 шт.	2021-01-11 23:08:39+00	833293	80	5	\N	2021-01-28 23:09:32.804+00	2021-01-28 23:09:32.804+00
\.


--
-- Data for Name: order_goods; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.order_goods ("orderId", "goodId", amount, "priceId", "createdAt", "updatedAt") FROM stdin;
1	1	1	26	2021-01-29 00:50:01.176099+00	2021-01-29 00:50:01.176099+00
1	6	1	6	2021-01-29 00:50:01.176099+00	2021-01-29 00:50:01.176099+00
2	16	2	16	2021-01-29 00:50:57.61246+00	2021-01-29 00:50:57.61246+00
2	11	20	11	2021-01-29 00:50:57.61246+00	2021-01-29 00:50:57.61246+00
3	13	15	13	2021-01-29 01:02:20.237474+00	2021-01-29 01:02:20.237474+00
3	14	1	14	2021-01-29 01:02:20.237474+00	2021-01-29 01:02:20.237474+00
4	3	1	3	2021-01-29 01:03:23.117613+00	2021-01-29 01:03:23.117613+00
4	19	1	19	2021-01-29 01:03:23.117613+00	2021-01-29 01:03:23.117613+00
5	3	1	3	2021-01-29 01:03:42.221746+00	2021-01-29 01:03:42.221746+00
5	19	1	19	2021-01-29 01:03:42.221746+00	2021-01-29 01:03:42.221746+00
6	20	1	20	2021-01-29 01:04:04.547347+00	2021-01-29 01:04:04.547347+00
6	3	4	3	2021-01-29 01:04:04.547347+00	2021-01-29 01:04:04.547347+00
7	8	4	8	2021-01-29 01:04:54.822465+00	2021-01-29 01:04:54.822465+00
7	16	3	16	2021-01-29 01:04:54.822465+00	2021-01-29 01:04:54.822465+00
8	6	1	6	2021-01-29 01:05:48.161535+00	2021-01-29 01:05:48.161535+00
8	18	2	18	2021-01-29 01:05:48.161535+00	2021-01-29 01:05:48.161535+00
8	5	5	23	2021-01-29 01:05:48.161535+00	2021-01-29 01:05:48.161535+00
9	19	20	19	2021-01-29 01:06:38.721271+00	2021-01-29 01:06:38.721271+00
10	20	2	20	2021-01-29 01:07:30.955281+00	2021-01-29 01:07:30.955281+00
10	17	1	17	2021-01-29 01:07:30.955281+00	2021-01-29 01:07:30.955281+00
10	14	2	14	2021-01-29 01:07:30.955281+00	2021-01-29 01:07:30.955281+00
11	8	6	8	2021-01-29 01:08:22.425995+00	2021-01-29 01:08:22.425995+00
11	1	1	33	2021-01-29 01:08:22.425995+00	2021-01-29 01:08:22.425995+00
12	9	3	28	2021-01-29 01:09:03.763387+00	2021-01-29 01:09:03.763387+00
12	5	1	23	2021-01-29 01:09:03.763387+00	2021-01-29 01:09:03.763387+00
12	4	2	32	2021-01-29 01:09:03.763387+00	2021-01-29 01:09:03.763387+00
\.


--
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.orders (id, "userId", status, "createdAt", "updatedAt") FROM stdin;
7	2	Processing	2021-01-29 01:04:54.822465+00	2021-01-29 01:04:54.822465+00
9	11	Processing	2021-01-29 01:06:38.721271+00	2021-01-29 01:06:38.721271+00
4	7	Rejected	2021-01-29 01:03:23.117613+00	2021-01-29 01:11:05.984+00
1	7	Arrived	2021-01-29 00:50:01.176099+00	2021-01-29 01:11:16.419+00
6	2	Arrived	2021-01-29 01:04:04.547347+00	2021-01-29 01:11:36.057+00
11	13	Arrived	2021-01-29 01:08:22.425995+00	2021-01-29 01:11:52.825+00
8	2	Arrived	2021-01-29 01:05:48.161535+00	2021-01-29 01:12:07.344+00
5	2	Accepted	2021-01-29 01:03:42.221746+00	2021-01-29 01:12:11.206+00
10	11	In transit	2021-01-29 01:07:30.955281+00	2021-01-29 01:12:18.865+00
12	13	Arrived	2021-01-29 01:09:03.763387+00	2021-01-29 01:12:35.121+00
3	7	Rejected	2021-01-29 01:02:20.237474+00	2021-01-29 01:12:40.59+00
2	7	Arrived	2021-01-29 00:50:57.61246+00	2021-01-29 01:13:25.06+00
\.


--
-- Data for Name: prices; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.prices (id, "goodId", price, "createdAt", "updatedAt") FROM stdin;
1	1	20000.00	2021-01-28 21:34:15.724+00	2021-01-28 21:34:15.724+00
2	2	25000.00	2021-01-28 21:35:42.562+00	2021-01-28 21:35:42.562+00
3	3	100000.00	2021-01-28 21:37:31.056+00	2021-01-28 21:37:31.056+00
4	4	600.00	2021-01-28 21:38:49.307+00	2021-01-28 21:38:49.307+00
5	5	60.00	2021-01-28 21:40:11.761+00	2021-01-28 21:40:11.761+00
6	6	500.00	2021-01-28 21:43:43.103+00	2021-01-28 21:43:43.103+00
7	7	900.00	2021-01-28 21:45:39.868+00	2021-01-28 21:45:39.868+00
8	8	1100.00	2021-01-28 23:05:33.904+00	2021-01-28 23:05:33.904+00
9	9	99.00	2021-01-28 23:07:26.15+00	2021-01-28 23:07:26.15+00
10	10	17500.00	2021-01-28 23:08:27.076+00	2021-01-28 23:08:27.076+00
11	11	70.00	2021-01-28 23:09:32.814+00	2021-01-28 23:09:32.814+00
12	12	200000.00	2021-01-28 23:11:03.525+00	2021-01-28 23:11:03.525+00
13	13	180.00	2021-01-28 23:16:50.25+00	2021-01-28 23:16:50.25+00
14	14	15000.00	2021-01-28 23:23:04.887+00	2021-01-28 23:23:04.887+00
15	15	14600.00	2021-01-29 00:27:00.897+00	2021-01-29 00:27:00.897+00
16	16	600.00	2021-01-29 00:28:16.298+00	2021-01-29 00:28:16.298+00
17	17	100000.00	2021-01-29 00:29:32.548+00	2021-01-29 00:29:32.548+00
18	18	180.00	2021-01-29 00:30:59.414+00	2021-01-29 00:30:59.414+00
19	19	150.00	2021-01-29 00:32:20.218+00	2021-01-29 00:32:20.218+00
20	20	450.00	2021-01-29 00:33:21.181+00	2021-01-29 00:33:21.181+00
21	10	16500.00	2021-01-29 00:33:42.304+00	2021-01-29 00:33:42.304+00
22	12	350000.00	2021-01-29 00:33:55.577+00	2021-01-29 00:33:55.577+00
23	5	79.00	2021-01-29 00:34:48.21+00	2021-01-29 00:34:48.21+00
24	10	16000.00	2021-01-29 00:34:58.803+00	2021-01-29 00:34:58.803+00
25	1	22000.00	2021-01-29 00:35:06.492+00	2021-01-29 00:35:06.492+00
26	1	21990.00	2021-01-29 00:36:08.752+00	2021-01-29 00:36:08.752+00
27	15	13990.00	2021-01-29 00:36:27.607+00	2021-01-29 00:36:27.607+00
28	9	62.00	2021-01-29 00:36:38.115+00	2021-01-29 00:36:38.115+00
29	4	350.00	2021-01-29 00:36:44.789+00	2021-01-29 00:36:44.789+00
30	15	13900.00	2021-01-29 00:37:34.319+00	2021-01-29 00:37:34.319+00
31	2	26000.00	2021-01-29 00:37:50.229+00	2021-01-29 00:37:50.229+00
32	4	450.00	2021-01-29 00:38:04.456+00	2021-01-29 00:38:04.456+00
33	1	20000.00	2021-01-29 00:51:54.405+00	2021-01-29 00:51:54.405+00
\.


--
-- Data for Name: refreshTokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."refreshTokens" (id, "userId", token, exp, "createdByIp", revoked, "revokedByIp", "replacedByToken", "createdAt", "updatedAt") FROM stdin;
1	1	facb839932bc75e46c521cecfed737f9780ebd9033ba2f04f5305d069fc648ffcb9875bfc36a0037	2021-02-04 21:30:26.705+00	::1	2021-01-28 23:05:33.872+00	::1	ccbb8a220ef28c8b33d7d679d67bcbbbb96249363182b3b084960e0dfcde8e86442bf422393e53b0	2021-01-28 21:30:26.705+00	2021-01-28 23:05:33.872+00
2	1	ccbb8a220ef28c8b33d7d679d67bcbbbb96249363182b3b084960e0dfcde8e86442bf422393e53b0	2021-02-04 23:05:33.862+00	::1	2021-01-29 00:27:00.869+00	::1	36d5f0e60b812914b391110b1ea91ede96eb0ca4cacb1c52a8e9e00351b7db70f2499604a9be9bfc	2021-01-28 23:05:33.862+00	2021-01-29 00:27:00.869+00
3	1	36d5f0e60b812914b391110b1ea91ede96eb0ca4cacb1c52a8e9e00351b7db70f2499604a9be9bfc	2021-02-05 00:27:00.853+00	::1	2021-01-29 00:41:29.807+00	::1	5a7739fe1d310c299a2391aef2205c5090c9037fab2348bb85dc43ae5b6f4b96af489d193d8356fd	2021-01-29 00:27:00.854+00	2021-01-29 00:41:29.807+00
4	1	5a7739fe1d310c299a2391aef2205c5090c9037fab2348bb85dc43ae5b6f4b96af489d193d8356fd	2021-02-05 00:41:29.773+00	::1	2021-01-29 00:43:56.602+00	::1	36c8031aadbc9dba8058705aceb51e8183d0b19b67b088f98e9b8ebae129803a31ac7f0a75e4fe51	2021-01-29 00:41:29.776+00	2021-01-29 00:43:56.602+00
5	1	36c8031aadbc9dba8058705aceb51e8183d0b19b67b088f98e9b8ebae129803a31ac7f0a75e4fe51	2021-02-05 00:43:56.562+00	::1	2021-01-29 00:46:29.58+00	::1	f1c4b0068b5e4f006334a459dff2bedd973e82db6e9ec8e9aa9c12ea3df9489213a00d123522c117	2021-01-29 00:43:56.565+00	2021-01-29 00:46:29.58+00
7	7	c21231a4c73fd66e8d0d8a7c11e68b3627f9120c67c6fed55f789e80356cfad2e17f9285aadc6ff3	2021-02-05 00:49:50.563+00	::1	\N	\N	\N	2021-01-29 00:49:50.564+00	2021-01-29 00:49:50.564+00
6	1	f1c4b0068b5e4f006334a459dff2bedd973e82db6e9ec8e9aa9c12ea3df9489213a00d123522c117	2021-02-05 00:46:29.561+00	::1	2021-01-29 00:51:06.487+00	::1	bd06fe78559f8fe25bb896801fc074bd8bec1ec6163a2398e1ea09d498ceccff1b2a5953d0cdcb38	2021-01-29 00:46:29.562+00	2021-01-29 00:51:06.487+00
9	2	b9bc9df41d933d4e8e76374d7b8dbb9406d523cf0c1d410e5ac5d4793be06d72c9e050d3141760e2	2021-02-05 01:03:33.298+00	::1	\N	\N	\N	2021-01-29 01:03:33.298+00	2021-01-29 01:03:33.298+00
10	11	965d033bb2b4d53d53801bc74b6289bb053aa67e080c50b231d466007fca0a24c89099c8161ab1a3	2021-02-05 01:05:56.949+00	::1	\N	\N	\N	2021-01-29 01:05:56.949+00	2021-01-29 01:05:56.949+00
11	13	bdf0a499256cd6bc5664c6931b0892d571dcd7d442f752a19441ff87feb93520f58c0d0b8dd7964c	2021-02-05 01:07:49.763+00	::1	\N	\N	\N	2021-01-29 01:07:49.764+00	2021-01-29 01:07:49.764+00
8	1	bd06fe78559f8fe25bb896801fc074bd8bec1ec6163a2398e1ea09d498ceccff1b2a5953d0cdcb38	2021-02-05 00:51:06.474+00	::1	2021-01-29 01:09:11.696+00	::1	0b5f144c7524ea8bae276d9b3ef1e593973fd2937f5d3485f28fc3708023fc84fd7ccf920036dd64	2021-01-29 00:51:06.474+00	2021-01-29 01:09:11.696+00
12	1	0b5f144c7524ea8bae276d9b3ef1e593973fd2937f5d3485f28fc3708023fc84fd7ccf920036dd64	2021-02-05 01:09:11.679+00	::1	2021-01-29 02:10:11.269+00	::1	1cc88d170eb859371b9bd06ea52d8208df11ccef7d04bf69651ea3762fd1f0ebaf39ff52bffe7d1b	2021-01-29 01:09:11.68+00	2021-01-29 02:10:11.27+00
13	1	1cc88d170eb859371b9bd06ea52d8208df11ccef7d04bf69651ea3762fd1f0ebaf39ff52bffe7d1b	2021-02-05 02:10:11.248+00	::1	2021-01-29 02:57:12.797+00	::1	f43feee82fa67aee2826c32d320db6d6f6196ad9fa325bf68590f94699e933cd4910709f3bccd040	2021-01-29 02:10:11.248+00	2021-01-29 02:57:12.798+00
14	1	f43feee82fa67aee2826c32d320db6d6f6196ad9fa325bf68590f94699e933cd4910709f3bccd040	2021-02-05 02:57:12.753+00	::1	2021-01-29 03:08:45.906+00	::1	d1785b9d4cba5a271869c7c2c5075dca0387292b91406bfe0fb53b6f5806f409fde29be0aad63313	2021-01-29 02:57:12.759+00	2021-01-29 03:08:45.906+00
15	1	d1785b9d4cba5a271869c7c2c5075dca0387292b91406bfe0fb53b6f5806f409fde29be0aad63313	2021-02-05 03:08:45.879+00	::1	2021-01-29 03:09:06.061+00	::1	8fa044680047df31a41a89af6d24a1f43122d720008235e6afd7e1f87c11c3f38f1b3276cbe49f16	2021-01-29 03:08:45.879+00	2021-01-29 03:09:06.061+00
16	1	8fa044680047df31a41a89af6d24a1f43122d720008235e6afd7e1f87c11c3f38f1b3276cbe49f16	2021-02-05 03:09:05.99+00	::1	2021-01-29 03:10:28.694+00	::1	e66b353a25404e4a2607948f0385027adbe2deafea6c3215b3fd288b35d29355501bff9b3f238d17	2021-01-29 03:09:05.99+00	2021-01-29 03:10:28.695+00
17	1	e66b353a25404e4a2607948f0385027adbe2deafea6c3215b3fd288b35d29355501bff9b3f238d17	2021-02-05 03:10:28.627+00	::1	2021-01-29 03:12:09.789+00	::1	d0639f74b23ff84f6d0d4f2ff4f11f84f710a00bbfabc467af1ca66839f6583086c0ed48534d5713	2021-01-29 03:10:28.634+00	2021-01-29 03:12:09.789+00
19	1	71f1808631c577449e6ef9b94acf648ebf49baafbe67cfd9f8e5f419008b91b8dfeae43e6a7c90ab	2021-02-05 03:13:01.86+00	::1	\N	\N	\N	2021-01-29 03:13:01.86+00	2021-01-29 03:13:01.86+00
18	1	d0639f74b23ff84f6d0d4f2ff4f11f84f710a00bbfabc467af1ca66839f6583086c0ed48534d5713	2021-02-05 03:12:09.737+00	::1	2021-01-29 03:13:01.899+00	::1	71f1808631c577449e6ef9b94acf648ebf49baafbe67cfd9f8e5f419008b91b8dfeae43e6a7c90ab	2021-01-29 03:12:09.738+00	2021-01-29 03:13:01.899+00
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, login, lastname, firstname, "isBlocked", "lastLogin", "lastLoginIp", "passwordHash", role, "createdAt", "updatedAt") FROM stdin;
3	user2	Ширикова	Вероника	f	\N	\N	$2b$08$UGcAGdq4wNA25NIWiJBuxue8jaeVdwl8aSmeoyVVICh5g5YtQbKam	User	2021-01-28 21:25:19.987+00	2021-01-28 21:25:19.987+00
4	user3	Легашнев	Максим	f	\N	\N	$2b$08$q2GOX5rkj0mkW93ah6WuQuTzLokz/Fug8LI1vK0dXgiXOBrKwBFrS	User	2021-01-28 21:25:34.539+00	2021-01-28 21:25:34.539+00
5	user4	Помякшев	Илья	f	\N	\N	$2b$08$ivqj4j7LtD8A7fhLB0Cq..7qp4p9bX1grcEZI/ou9KEMivoudD3zK	User	2021-01-28 21:25:48.643+00	2021-01-28 21:25:48.643+00
8	user7	Азаров	Владимир	f	\N	\N	$2b$08$gdizsxW30VWvCK9rftpq8OnTN8uIWtq2FxTVuVHYfcSMshH.onCc.	User	2021-01-28 21:27:04.663+00	2021-01-28 21:27:04.663+00
9	user8	Маркичев	Кирилл	f	\N	\N	$2b$08$iDEGdJcOsgiuxCkuiURbvO.COxXC5IcN3W71zeER4enHxSIMyOfuu	User	2021-01-28 21:27:15.803+00	2021-01-28 21:27:15.803+00
10	user9	Акимов	Кирилл	f	\N	\N	$2b$08$QVwHmCJkNiCR64FE9MB3QusanL06xZcO3LcUZpzuXAfIhfpqw/eIS	User	2021-01-28 21:27:23.393+00	2021-01-28 21:27:23.393+00
12	user11	Иванов	Иван	f	\N	\N	$2b$08$fC/S5lXkY4SaF30yXTo8YuqDJYfS85YmEzNfVHwnh2LpMBJ7ODC4e	User	2021-01-28 21:27:58.052+00	2021-01-28 21:27:58.052+00
1	admin	Федоров	Дмитрий	f	2021-01-28 21:30:26.694+00	::1	$2b$08$qCChgpUArbhlBYgWvlNxhOSNdYOPjbk0XcCZukE5Inkdt5xIRXpU2	Admin	2021-01-28 21:24:18.196+00	2021-01-28 21:30:26.695+00
6	user5	Будников	Даниил	t	\N	\N	$2b$08$9h4oX/JqcEWZqocfuJZ2g.ojXZZ6BN.PbCNoJecrPPnhE9IXBgPGK	User	2021-01-28 21:26:23.465+00	2021-01-29 00:44:49.492+00
7	user6	Ермин	Егор	f	2021-01-29 00:49:50.546+00	::1	$2b$08$DKXtOkgZZ5UfJrw3/m6LWerRTHbHlRg7jEHIkJEw/8yYRJ4MkPOUS	User	2021-01-28 21:26:37.268+00	2021-01-29 00:49:50.547+00
2	user1	Чурсин	Павел	f	2021-01-29 01:03:33.289+00	::1	$2b$08$ARWtqwLW3SIDOuVhnzfrueV6C83N/XwRggY8Q4LsKq0SuOiP2kO5q	User	2021-01-28 21:25:01.838+00	2021-01-29 01:03:33.289+00
11	user10	Мельников	Глеб	f	2021-01-29 01:05:56.933+00	::1	$2b$08$NSIlWbaVAvZ3z4qNKnaWDOY1wyjO6AqV9h7OarXzsJPhrr0lW9Wfu	User	2021-01-28 21:27:46.373+00	2021-01-29 01:05:56.934+00
13	user12	Киселева	Людмила	f	2021-01-29 01:07:49.754+00	::1	$2b$08$evxzZoi4bEHa.HwLxJRwe.7jOXwvyx1cbPtrLq3PzZH4uRuk.UJve	User	2021-01-28 21:28:16.819+00	2021-01-29 01:07:49.754+00
\.


--
-- Name: categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.categories_id_seq', 5, true);


--
-- Name: goods_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.goods_id_seq', 20, true);


--
-- Name: orders_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.orders_id_seq', 12, true);


--
-- Name: prices_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.prices_id_seq', 33, true);


--
-- Name: refreshTokens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."refreshTokens_id_seq"', 19, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 13, true);


--
-- Name: categories categories_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_name_key UNIQUE (name);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: goods goods_partNumber_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.goods
    ADD CONSTRAINT "goods_partNumber_key" UNIQUE ("partNumber");


--
-- Name: goods goods_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.goods
    ADD CONSTRAINT goods_pkey PRIMARY KEY (id);


--
-- Name: order_goods order_goods_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_goods
    ADD CONSTRAINT order_goods_pkey PRIMARY KEY ("orderId", "goodId");


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: prices prices_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prices
    ADD CONSTRAINT prices_pkey PRIMARY KEY (id);


--
-- Name: refreshTokens refreshTokens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."refreshTokens"
    ADD CONSTRAINT "refreshTokens_pkey" PRIMARY KEY (id);


--
-- Name: users users_login_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_login_key UNIQUE (login);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: goods_statistics _RETURN; Type: RULE; Schema: public; Owner: postgres
--

CREATE OR REPLACE VIEW public.goods_statistics AS
 SELECT goods.id,
    goods.name,
    goods."manufacturedAt",
    goods."categoryId",
    goods.description,
    sum(order_goods.amount) AS amount,
    sum((prices.price * (order_goods.amount)::numeric)) AS price
   FROM (((public.order_goods
     JOIN public.goods ON ((goods.id = order_goods."goodId")))
     JOIN public.prices ON ((prices.id = order_goods."priceId")))
     JOIN public.orders ON ((orders.id = order_goods."orderId")))
  WHERE ((orders.status)::text = 'Arrived'::text)
  GROUP BY goods.id;


--
-- Name: category_statistics _RETURN; Type: RULE; Schema: public; Owner: postgres
--

CREATE OR REPLACE VIEW public.category_statistics AS
 SELECT categories.id,
    categories.name,
    sum(goods_statistics.amount) AS amount
   FROM (public.categories
     JOIN public.goods_statistics ON ((categories.id = goods_statistics."categoryId")))
  GROUP BY categories.id;


--
-- Name: orders order_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER order_trigger BEFORE INSERT OR UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.checkavailability();


--
-- Name: goods goods_categoryId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.goods
    ADD CONSTRAINT "goods_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES public.categories(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: order_goods order_goods_goodId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_goods
    ADD CONSTRAINT "order_goods_goodId_fkey" FOREIGN KEY ("goodId") REFERENCES public.goods(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: order_goods order_goods_orderId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_goods
    ADD CONSTRAINT "order_goods_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES public.orders(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: order_goods order_goods_priceId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_goods
    ADD CONSTRAINT "order_goods_priceId_fkey" FOREIGN KEY ("priceId") REFERENCES public.prices(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: orders orders_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT "orders_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prices prices_goodId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prices
    ADD CONSTRAINT "prices_goodId_fkey" FOREIGN KEY ("goodId") REFERENCES public.goods(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: refreshTokens refreshTokens_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."refreshTokens"
    ADD CONSTRAINT "refreshTokens_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

