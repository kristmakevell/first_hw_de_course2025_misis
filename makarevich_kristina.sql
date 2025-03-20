---НОМЕР1
-- categorty_name и abg_order_amount наши столбцы из ответа
-- внутри делаем сумму товаров из одной категории внутри заказа (SUM(order_items.quantity * products.price) AS total_order_value)
-- группируем сначала внутри заказа, потом по категориям (   GROUP BY orders.id, categories.name)
-- подсоединяем все таблицы друг через друга (JOINы)
-- выбираем подходящие по дате (WHERE)
-- записываем все это как inside_q
-- все получившееся группируем по category_name

SELECT
    category_name,
    ROUND(AVG(total_order_value), 2) AS avg_order_amount
FROM (
    SELECT
        orders.id AS order_id,
        categories.name AS category_name,
        SUM(order_items.quantity * products.price) AS total_order_value
    FROM orders
    JOIN order_items ON orders.id = order_items.order_id
    JOIN products ON order_items.product_id = products.id
    JOIN categories ON products.category_id = categories.id
    WHERE
        orders.created_at >= '2023-03-01 00:00:00'
        AND orders.created_at < '2023-04-01 00:00:00'
    GROUP BY
        orders.id, categories.name
) AS inside_q
GROUP BY
    category_name;


--НОМЕР2
-- выбираем нужные нам данные + пишем порядковый номер (тк сортируем по сумме, номер берем по ней)
-- присоединяем все нужные таблицы
-- мы вытягиваем сумму из payments, от нее берем номер заказа, от него получаем юзер_айди
-- группируем по юзерам
-- в порядке убывания тк нужны три верхних
-- ставим ограничение 3 тк нужны три верхних

SELECT name AS user_name, SUM(amount) AS total_spent, ROW_NUMBER() OVER (ORDER BY SUM(amount) DESC)
FROM users
JOIN orders ON orders.user_id=users.id
JOIN payments ON payments.order_id=orders.id
WHERE orders.status='Оплачен'
GROUP BY name
ORDER BY total_spent DESC
LIMIT 3;


--НОМЕР3
-- перевели в числа дату
-- посчитали сумму и количество
-- отфильтровали по месяуам
-- сгруппировали по месяцам
-- поставили по порядку

SELECT TO_CHAR(created_at, 'YYYY-MM') AS month, count(orders.id) AS total_orders, SUM(amount) as total_payments
FROM payments
JOIN orders ON orders.id=payments.order_id
WHERE created_at >= '2023-01-01 00:00:00'
    AND created_at < '2024-01-01 00:00:00'
GROUP BY month
ORDER BY month


--НОМЕР4
--выбрали все столбцы
--для третьего стобца внутренне посчитали общее количество проданных товаров
--присоединили все нужные таблицы
--выбрали верхние пять если сортировать по убыванию

SELECT name AS product_name, SUM(quantity) AS total_sold, 
ROUND(SUM(quantity) * 100.0 / (SELECT SUM(quantity) FROM order_items), 2) AS sales_percantage
FROM products
JOIN order_items ON order_items.product_id=products.id
GROUP BY product_name
ORDER BY total_sold DESC
LIMIT 5


--НОМЕР5
--выбрали нужные значения
--присоединили все нужные таблицы
--проверили статус
--установили условие что сумма наша больше среднего значения
--поставили в порядке убывания

SELECT name as user_name, SUM(amount) as total_spent FROM orders
JOIN payments ON payments.order_id=orders.id
JOIN users ON orders.user_id=users.id
WHERE status='Оплачен'
GROUP BY name
HAVING (SUM(amount)) > 
(SELECT AVG(amount) FROM payments
 JOIN orders ON orders.id=payments.order_id 
 WHERE status='Оплачен')
ORDER BY SUM(amount) DESC

--вот эти две проги маленькие это вопрос по этому номеру 
--потому что вроде как там еще одна строчка должна выводиться (анна анновна)
--вот это я как раз проверила среднюю сумму
SELECT SUM(amount) / COUNT(order_id)
FROM payments
JOIN orders ON orders.id=payments.order_id
WHERE status='Оплачен'

--а это проверила анну как раз
--и вроде должно подходить??
SELECT SUM(amount) 
FROM payments
JOIN orders ON orders.id=payments.order_id
JOIN users ON users.id=orders.user_id
WHERE users.id=4 AND orders.status='Оплачен'


--НОМЕР6
--выбрали все нужные данные
--делаем внутренний select
--делаем внутри оконную функцию которая нам считает порядок
--join все нужное
--проверяем что ранк меньше четырех
--сортируем по порядку
SELECT category_name, product_name, total_sold
FROM (
    SELECT 
        categories.name AS category_name, 
        products.name AS product_name, 
        SUM(order_items.quantity) AS total_sold,
        RANK() OVER (PARTITION BY categories.name ORDER BY SUM(quantity) DESC) AS ranking
    FROM categories
    JOIN products ON products.category_id = categories.id
    JOIN order_items ON products.id = order_items.product_id
    GROUP BY categories.name, products.name
) as already_ranked
WHERE ranking <= 3
ORDER BY category_name, total_sold DESC, product_name DESC


--НОМЕР7
--выбираем нужные данные
--делаем внутри оконную функцию по времени и сумме
--присоединяем все таблицы
--берем по rankin первую строчку в каждом месяце

SELECT month, category_name, total_revenue
FROM (
    SELECT
    TO_CHAR(created_at, 'YYYY-MM') AS month,
    categories.name AS category_name,
    SUM(quantity * price) AS total_revenue,
    RANK() OVER (PARTITION BY TO_CHAR(created_at, 'YYYY-MM') ORDER BY SUM(quantity * price) DESC) AS rankin
    FROM order_items
    JOIN orders ON orders.id=order_items.order_id
    JOIN products ON products.id=order_items.product_id
    JOIN categories ON categories.id=products.category_id
    GROUP BY TO_CHAR(created_at, 'YYYY-MM'), categories.name
) AS subcc
WHERE rankin=1
ORDER BY month


--НОМЕР8
--выбрали все нужные данные
--последний столбик - оконная функция, где мы складываем нашу строчку и все строчки до этого
--присоединяем все таблицы
--проверяем что оно оплаченное
--проверяем что 2023 год

SELECT TO_CHAR(payment_date, 'YYYY-MM') AS month, 
SUM(quantity * price) AS monthly_payments,
SUM(SUM(quantity * price)) OVER (ORDER BY TO_CHAR(payment_date, 'YYYY-MM') 
ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_payments
FROM orders
JOIN payments ON payments.order_id=orders.id
JOIN order_items ON order_items.order_id=orders.id
JOIN products ON products.id=order_items.product_id
WHERE TO_CHAR(payment_date, 'YYYY') IS NOT NULL 
AND TO_CHAR(payment_date, 'YYYY')='2023'
GROUP BY month
ORDER BY month

