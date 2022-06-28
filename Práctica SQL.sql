USE GDD2022C1
GO

--FALTA HACER: 32
--FALTA CORREGIR: 33, 34, 35
--ENVIADOS: 24, 25, 26, 27, 28 (31), 29, 30
--CORREGIDOS: 16, 18, 22
/*-------------------------------------------------------------------------------------------------

                                         CLASE 12/04/2022

---------------------------------------------------------------------------------------------------*/

/* 1. Mostrar el c�digo, raz�n social de todos los clientes cuyo l�mite de cr�dito sea mayor o igual
a $ 1000 ordenado por c�digo de cliente.*/

SELECT clie_codigo, clie_razon_social
FROM Cliente
WHERE clie_limite_credito >= 1000
ORDER BY clie_codigo

/*2. Mostrar el c�digo, detalle de todos los art�culos vendidos en el a�o 2012 ordenados por cantidad 
vendida.*/

SELECT prod_codigo, prod_detalle
FROM Producto
JOIN Item_Factura on (item_producto = prod_codigo)
JOIN Factura on (fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero)
WHERE YEAR(fact_fecha) = 2012
GROUP BY prod_codigo, prod_detalle
ORDER BY SUM(item_cantidad)

/*-------------------------------------------------------------------------------------------------

                                         CLASE 19/04/2022

---------------------------------------------------------------------------------------------------*/

/*3. Realizar una consulta que muestre c�digo de producto, nombre de producto y el stock total, sin
importar en que deposito se encuentre, los datos deben ser ordenados por nombre del art�culo de menor
a mayor.*/ -- LO HICE YO -- REVISAR

SELECT p.prod_codigo, p.prod_detalle, SUM(ISNULL(s.stoc_cantidad, 0))
FROM Producto p
LEFT JOIN STOCK s on s.stoc_producto = p.prod_codigo
GROUP BY p.prod_codigo, p.prod_detalle
ORDER BY p.prod_detalle

/*4. Realizar una consulta que muestre para todos los art�culos c�digo, detalle y cantidad de art�culos 
que lo componen. Mostrar solo aquellos art�culos para los cuales el stock promedio por dep�sito sea
mayor a 100.*/

SELECT prod_codigo, prod_detalle, ISNULL(SUM(c.comp_cantidad), 0) as Cantidad
FROM Producto p
LEFT JOIN Composicion c on p.prod_codigo = c.comp_producto
WHERE (SELECT avg(s.stoc_cantidad) FROM STOCK s where s.stoc_producto = p.prod_codigo) > 100
GROUP BY prod_codigo, prod_detalle

/*5. Realizar una consulta que muestre c�digo de art�culo, detalle y cantidad de egresos de stock que 
se realizaron para ese art�culo en el a�o 2012 (egresan los productos que fueron vendidos). Mostrar 
solo aquellos que hayan tenido m�s egresos que en el 2011.*/

SELECT p.prod_codigo, p.prod_detalle, SUM(i.item_cantidad) as Cantidad
FROM Producto p 
INNER JOIN Item_Factura i on p.prod_codigo = i.item_producto
INNER JOIN Factura f on f.fact_tipo+f.fact_sucursal+f.fact_numero = i.item_tipo+i.item_sucursal+i.item_numero
WHERE YEAR(f.fact_fecha) = 2012
GROUP BY p.prod_codigo, p.prod_detalle
HAVING SUM(i.item_cantidad) > ISNULL((SELECT SUM(i2.item_cantidad)
							   FROM Item_Factura i2
							   INNER JOIN Factura f2 on f2.fact_tipo+f2.fact_sucursal+f2.fact_numero = i2.item_tipo+i2.item_sucursal+i2.item_numero
							   WHERE YEAR(f2.fact_fecha) = 2011 AND i2.item_producto = p.prod_codigo), 0)

/*6. Mostrar para todos los rubros de art�culos c�digo, detalle, cantidad de art�culos de ese rubro
y stock total de ese rubro de art�culos. Solo tener en cuenta aquellos art�culos que tengan un stock
 mayor al del art�culo �00000000� en el dep�sito �00�.*/

 SELECT rubr_id, rubr_detalle, COUNT(*) as cantidad_articulos, 
	(SELECT SUM(s.stoc_cantidad)
	FROM Producto p
	INNER JOIN STOCK s on s.stoc_producto = p.prod_codigo
	WHERE p.prod_rubro = r.rubr_id
	HAVING SUM(s.stoc_cantidad) > (SELECT stoc_cantidad 
	  							   FROM STOCK s2 
								   WHERE s2.stoc_producto = '00000000' 
								   AND s2.stoc_deposito = '00')) as cantidad_stock
 FROM Rubro r
 LEFT JOIN Producto p on r.rubr_id = p.prod_rubro
 GROUP BY rubr_id, rubr_detalle

/*7. Generar una consulta que muestre para cada art�culo c�digo, detalle, mayor precio, menor precio
y % de la diferencia de precios (respecto del menor Ej.: menor precio = 10, mayor precio = 12 => mostrar 20 %). 
Mostrar solo aquellos art�culos que posean stock.*/

SELECT p.prod_codigo, p.prod_detalle, MAX(i.item_precio) as Mayor, MIN(i.item_precio) as Menor, 
CONVERT(DECIMAL(5,2), ROUND((MAX(i.item_precio) - MIN(i.item_precio)) * 100 / MIN(i.item_precio), 2)) as Porcentaje
FROM Producto p 
INNER JOIN Item_Factura i on p.prod_codigo = i.item_producto
GROUP BY prod_codigo, prod_detalle
HAVING EXISTS (SELECT 1 FROM STOCK s WHERE s.stoc_cantidad > 0 AND s.stoc_producto = p.prod_codigo)

/*8. Mostrar para el o los art�culos que tengan stock en todos los dep�sitos, nombre del art�culo, 
stock del dep�sito que m�s stock tiene.*/

SELECT prod_detalle, MAX(s.stoc_cantidad) as mayor_stock
FROM Producto p
INNER JOIN STOCK s on p.prod_codigo = s.stoc_producto
WHERE s.stoc_cantidad > 0
GROUP BY prod_codigo, prod_detalle
HAVING COUNT(*) = (SELECT COUNT(DISTINCT s1.stoc_deposito) FROM STOCK s1) --(SELECT COUNT(*) FROM DEPOSITO) ser�a lo correcto pero no todos los dep�sitos tienen stock de algo (Se toman solo los dep�sitos con stock de algo)

/*9. Mostrar el c�digo del jefe, c�digo del empleado que lo tiene como jefe, nombre del mismo y la 
cantidad de dep�sitos que ambos tienen asignados.*/

SELECT empl_jefe as codigo_Jefe, empl_codigo as codigo_Empleado, CONCAT(RTRIM(empl_apellido), ', ', RTRIM(empl_nombre)) as nombre, COUNT(*)
FROM Empleado INNER JOIN DEPOSITO on empl_jefe = depo_encargado or empl_codigo = depo_encargado
GROUP BY empl_jefe, empl_codigo, CONCAT(RTRIM(empl_apellido), ', ', RTRIM(empl_nombre))

/*10. Mostrar los 10 productos m�s vendidos en la historia y tambi�n los 10 productos menos vendidos
en la historia. Adem�s mostrar de esos productos, quien fue el cliente que mayor compra realizo.*/

SELECT p.prod_codigo, (SELECT top 1 f.fact_cliente
					   FROM Item_Factura i2
					   INNER JOIN Factura f on f.fact_tipo+f.fact_sucursal+f.fact_numero = i2.item_tipo+i2.item_sucursal+i2.item_numero
					   WHERE i2.item_producto = p.prod_codigo
					   GROUP BY f.fact_cliente
					   ORDER BY sum(i2.item_cantidad) DESC) as cliente
FROM Producto p
WHERE p.prod_codigo IN (SELECT top 10 i.item_producto FROM Item_Factura i
						GROUP BY i.item_producto ORDER BY SUM(i.item_cantidad)) 
OR P.prod_codigo IN (SELECT top 10 i.item_producto FROM Item_Factura i
					 GROUP BY i.item_producto ORDER BY SUM(i.item_cantidad) DESC)
ORDER BY 1

/*11. Realizar una consulta que retorne el detalle de la familia, la cantidad diferentes de productos
vendidos y el monto de dichas ventas sin impuestos. Los datos se deber�n ordenar de mayor a menor,
por la familia que m�s productos diferentes vendidos tenga, solo se deber�n mostrar las familias 
que tengan una venta superior a 20000 pesos para el a�o 2012.*/

SELECT f.fami_detalle, COUNT(DISTINCT i.item_producto) as productos, SUM(i.item_cantidad * i.item_precio) as importes
FROM Familia f
INNER JOIN Producto p on f.fami_id = p.prod_familia
INNER JOIN Item_Factura i on p.prod_codigo = i.item_producto
WHERE (SELECT SUM(i2.item_cantidad * i2.item_precio)
		FROM Producto p2
		INNER JOIN Item_Factura i2 on p2.prod_codigo = i2.item_producto
		INNER JOIN Factura f2 on f2.fact_tipo+f2.fact_sucursal+f2.fact_numero = i2.item_tipo+i2.item_sucursal+i2.item_numero
		WHERE YEAR(f2.fact_fecha) = 2012 AND p2.prod_familia = f.fami_id) > 20000
GROUP BY f.fami_id, f.fami_detalle
ORDER BY COUNT(DISTINCT i.item_producto) DESC

/*12. Mostrar nombre de producto, cantidad de clientes distintos que lo compraron, importe promedio 
pagado por el producto, cantidad de dep�sitos en los cuales hay stock del producto y stock actual del
producto en todos los dep�sitos. Se deber�n mostrar aquellos productos que hayan tenido operaciones
en el a�o 2012 y los datos deber�n ordenarse de mayor a menor por monto vendido del producto.*/

SELECT p.prod_detalle, COUNT(DISTINCT f.fact_cliente) as cant_clientes, AVG(i.item_precio) as precio_promedio,
(SELECT COUNT(*) FROM STOCK s WHERE s.stoc_producto = p.prod_codigo AND stoc_cantidad > 0) as depositos,
(SELECT SUM(s.stoc_cantidad) FROM STOCK s WHERE s.stoc_producto = p.prod_codigo) as stock_total
FROM Producto p
INNER JOIN Item_Factura i on p.prod_codigo = i.item_producto
INNER JOIN Factura f on f.fact_tipo+f.fact_sucursal+f.fact_numero = i.item_tipo+i.item_sucursal+i.item_numero
GROUP BY p.prod_codigo, p.prod_detalle
HAVING EXISTS (SELECT 1 FROM Item_Factura I2
						INNER JOIN Factura f2 on f2.fact_tipo+f2.fact_sucursal+f2.fact_numero = i2.item_tipo+i2.item_sucursal+i2.item_numero
					    WHERE i2.item_producto = p.prod_codigo AND YEAR(f2.fact_fecha) = 2012)
ORDER BY SUM(i.item_cantidad * i.item_precio) DESC

/*13. Realizar una consulta que retorne para cada producto que posea composici�n nombre del producto,
precio del producto, precio de la sumatoria de los precios por la cantidad de los productos que lo 
componen. Solo se deber�n mostrar los productos que est�n compuestos por m�s de 2 productos y deben 
ser ordenados de mayor a menor por cantidad de productos que lo componen.*/

SELECT p.prod_detalle, p.prod_precio, SUM(p2.prod_precio * c.comp_cantidad) as suma_precios_componentes
FROM Producto p
INNER JOIN Composicion c on p.prod_codigo = c.comp_producto
INNER JOIN Producto p2 on c.comp_componente = p2.prod_codigo
GROUP BY p.prod_codigo, p.prod_detalle, p.prod_precio
HAVING SUM(c.comp_cantidad) > 2
ORDER BY SUM(c.comp_cantidad) DESC

SELECT * 
FROM Producto WHERE prod_codigo in ('00006408', '00006409')

/*14. Escriba una consulta que retorne una estad�stica de ventas por cliente. Los campos que debe 
retornar son:
  
  -C�digo del cliente
  -Cantidad de veces que compro en el �ltimo a�o
  -Promedio por compra en el �ltimo a�o
  -Cantidad de productos diferentes que compro en el �ltimo a�o
  -Monto de la mayor compra que realizo en el �ltimo a�o

Se deber�n retornar todos los clientes ordenados por la cantidad de veces que compro en
el �ltimo a�o.
No se deber�n visualizar NULLs en ninguna columna*/

SELECT c.clie_codigo, COUNT(DISTINCT f.fact_numero) as veces_que_compro, ISNULL(AVG(f.fact_total), 0) as promedio_compra,
COUNT(DISTINCT(i.item_producto)) as productos_distintos, ISNULL(MAX(f.fact_total), 0) as maximo_total
FROM Cliente c
INNER JOIN Factura f on f.fact_cliente = c.clie_codigo
INNER JOIN Item_Factura i on f.fact_tipo+f.fact_sucursal+f.fact_numero = i.item_tipo+i.item_sucursal+i.item_numero
WHERE YEAR(f.fact_fecha) = YEAR(GETDATE())
GROUP BY c.clie_codigo
UNION ALL
SELECT c.clie_codigo, 0 as veces_que_compro, 0 as promedio_compra, 0 as productos_distintos, 0 as maximo_total
FROM Cliente c
WHERE NOT EXISTS (SELECT 1 FROM Factura f
				  WHERE YEAR(f.fact_fecha) = YEAR(GETDATE()) AND f.fact_cliente = c.clie_codigo)
ORDER BY 2 DESC

/*15. Escriba una consulta que retorne los pares de productos que hayan sido vendidos juntos (en la
misma factura) m�s de 500 veces. El resultado debe mostrar el c�digo y descripci�n de cada uno de los
productos y la cantidad de veces que fueron vendidos juntos. El resultado debe estar ordenado por la
cantidad de veces que se vendieron juntos dichos productos. Los distintos pares no deben retornarse
m�s de una vez.

Ejemplo de lo que retornar�a la consulta:

PROD1 DETALLE1 PROD2 DETALLE2 VECES
1731 MARLBORO KS 1718 Linterna con pilas 507
1705 PHILIPS MORRIS KS 1718 Linterna con pilas 10 562 */

SELECT i.item_producto, i2.item_producto, p.prod_detalle, p2.prod_detalle, COUNT(*) as cantidad
FROM Item_Factura i
INNER JOIN Item_Factura i2 on i.item_numero+i.item_sucursal+i.item_tipo = i2.item_numero+i2.item_sucursal+i2.item_tipo
INNER JOIN Producto p on p.prod_codigo = i.item_producto
INNER JOIN Producto p2 on p2.prod_codigo = i2.item_producto
WHERE i.item_producto < i2.item_producto -- Esta linea evita los repetidos
GROUP BY i.item_producto, i2.item_producto, p.prod_detalle, p2.prod_detalle
HAVING COUNT(*) > 500

/*-------------------------------------------------------------------------------------------------

                                         CLASE 26/04/2022

---------------------------------------------------------------------------------------------------*/

/*16. Con el fin de lanzar una nueva campa�a comercial para los clientes que menos compran en la 
empresa, se pide una consulta SQL que retorne aquellos clientes cuyas ventas son inferiores a 1/3 del
promedio de ventas del producto que m�s se vendi� en el 2012.

Adem�s mostrar
  1. Nombre del Cliente
  2. Cantidad de unidades totales vendidas en el 2012 para ese cliente.
  3. C�digo de producto que mayor venta tuvo en el 2012 (en caso de existir m�s de 1, mostrar solamente
     el de menor c�digo) para ese cliente.

Aclaraciones:
La composici�n es de 2 niveles, es decir, un producto compuesto solo se compone de productos no compuestos.
Los clientes deben ser ordenados por c�digo de provincia ascendente.*/

--NO RETORNA VALORES PORQUE NO HAY NINGUNO QUE CUMPLA CON LA CONDICI�N
SELECT c.clie_razon_social as [Cliente], SUM(i.item_cantidad) as [Unidades vendidas en 2012], 
	   (SELECT TOP 1 i2.item_producto
		FROM Cliente c2
		JOIN Factura f2 ON f2.fact_cliente = c2.clie_codigo
		JOIN Item_Factura i2 ON f2.fact_tipo+f2.fact_sucursal+f2.fact_numero = i2.item_tipo+i2.item_sucursal+i2.item_numero
		WHERE c.clie_razon_social = c2.clie_razon_social
		GROUP BY c2.clie_razon_social, i2.item_producto
		ORDER BY SUM(i2.item_cantidad) DESC) as [Prod mas vendido a ese cliente]
FROM Cliente c
JOIN Factura f ON f.fact_cliente = c.clie_codigo
JOIN Item_Factura i ON f.fact_tipo+f.fact_sucursal+f.fact_numero = i.item_tipo+i.item_sucursal+i.item_numero
WHERE YEAR(f.fact_fecha) = 2012
GROUP BY c.clie_razon_social
HAVING SUM(i.item_cantidad) < ((SELECT AVG(i2.item_cantidad)
							 FROM Factura f2
							 INNER JOIN Item_Factura i2 ON f2.fact_tipo+f2.fact_sucursal+f2.fact_numero = i2.item_tipo+i2.item_sucursal+i2.item_numero
							 WHERE i2.item_producto = (SELECT TOP 1 i3.item_producto FROM Factura f3
													INNER JOIN Item_Factura i3 on f3.fact_tipo+f3.fact_sucursal+f3.fact_numero = i3.item_tipo+i3.item_sucursal+i3.item_numero
													WHERE YEAR(f3.fact_fecha) = 2012
													GROUP BY i3.item_producto
													ORDER BY SUM(i3.item_cantidad) DESC)) / 3) 
													
--Producto mas vendido por cliente

SELECT TOP 1 i.item_producto
FROM Cliente c
JOIN Factura f ON f.fact_cliente = c.clie_codigo
JOIN Item_Factura i ON f.fact_tipo+f.fact_sucursal+f.fact_numero = i.item_tipo+i.item_sucursal+i.item_numero
GROUP BY c.clie_razon_social, i.item_producto
ORDER BY SUM(i.item_cantidad) DESC

SELECT TOP 1 i.item_producto
FROM Cliente c
JOIN Factura f ON f.fact_cliente = c.clie_codigo
JOIN Item_Factura i ON f.fact_tipo+f.fact_sucursal+f.fact_numero = i.item_tipo+i.item_sucursal+i.item_numero
WHERE c.clie_razon_social = 'AYALA JUAN JOSE' AND YEAR(f.fact_fecha) = 2012
GROUP BY c.clie_razon_social, i.item_producto
ORDER BY SUM(i.item_cantidad) DESC


--Este es el promedio de ventas del producto mas vendido del 2012 
SELECT AVG(i.item_cantidad)
FROM Factura f
INNER JOIN Item_Factura i ON f.fact_tipo+f.fact_sucursal+f.fact_numero = i.item_tipo+i.item_sucursal+i.item_numero
WHERE i.item_producto = (SELECT TOP 1 i2.item_producto FROM Factura f2
						 INNER JOIN Item_Factura i2 on f2.fact_tipo+f2.fact_sucursal+f2.fact_numero = i2.item_tipo+i2.item_sucursal+i2.item_numero
						 WHERE YEAR(f2.fact_fecha) = 2012
						 GROUP BY i2.item_producto
						 ORDER BY SUM(i2.item_cantidad) DESC)

 --Este es el prod mas vendido del 2012
SELECT TOP 1 i.item_producto 
FROM Factura f
INNER JOIN Item_Factura i on f.fact_tipo+f.fact_sucursal+f.fact_numero = i.item_tipo+i.item_sucursal+i.item_numero
WHERE YEAR(f.fact_fecha) = 2012
GROUP BY i.item_producto
ORDER BY SUM(i.item_cantidad) DESC


/*17. Escriba una consulta que retorne una estad�stica de ventas por a�o y mes para cada producto.

La consulta debe retornar:

  PERIODO: A�o y mes de la estad�stica con el formato YYYYMM
  PROD: C�digo de producto
  DETALLE: Detalle del producto
  CANTIDAD_VENDIDA = Cantidad vendida del producto en el periodo
  VENTAS_A�O_ANT = Cantidad vendida del producto en el mismo mes del periodo pero del a�o anterior
  CANT_FACTURAS = Cantidad de facturas en las que se vendi� el producto en el periodo

La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada por periodo y 
c�digo de producto.*/--Hecho en clase

SELECT FORMAT(f.fact_fecha, 'yyyyMM') as Periodo, prod_codigo, prod_detalle, SUM(item_cantidad) as cantidad_vendida, 
	ISNULL((SELECT SUM(i2.item_cantidad)
	FROM Factura f2
	INNER JOIN Item_Factura i2 on f2.fact_tipo+f2.fact_sucursal+f2.fact_numero = i2.item_tipo+i2.item_sucursal+i2.item_numero
	WHERE YEAR(f2.fact_fecha) = (YEAR(f.fact_fecha) - 1)  AND MONTH(f2.fact_fecha) = MONTH(f.fact_fecha) AND i2.item_producto = p.prod_codigo
	), 0) as ventas_anio_anterior,
	
	COUNT(DISTINCT f.fact_tipo+f.fact_sucursal+f.fact_numero) as cantidad_facturas

FROM Factura f
INNER JOIN Item_Factura i on f.fact_tipo+f.fact_sucursal+f.fact_numero = i.item_tipo+i.item_sucursal+i.item_numero
INNER JOIN Producto p on p.prod_codigo = i.item_producto
GROUP BY YEAR(f.fact_fecha), MONTH(f.fact_fecha), FORMAT(f.fact_fecha, 'yyyyMM'), p.prod_codigo, p.prod_detalle
ORDER BY YEAR(f.fact_fecha), MONTH(f.fact_fecha), p.prod_codigo

 --TOMA 4 MINUTOS EJECUTAR (AL PROFE LE ANDABA BIEN)


/*18. Escriba una consulta que retorne una estad�stica de ventas para todos los rubros.

La consulta debe retornar:

  DETALLE_RUBRO: Detalle del rubro
  VENTAS: Suma de las ventas en pesos de productos vendidos de dicho rubro
  PROD1: C�digo del producto m�s vendido de dicho rubro
  PROD2: C�digo del segundo producto m�s vendido de dicho rubro
  CLIENTE: C�digo del cliente que compro m�s productos del rubro en los �ltimos 30 d�as

La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada
por cantidad de productos diferentes vendidos del rubro.*/
--Interpretaciones m�as:
		--(Se toma como �ltimos 30 d�as a los �ltimos d�as facturados de la base de datos)


SELECT r.rubr_detalle as [Rubro],
	ISNULL((SELECT SUM(i2.item_precio * i2.item_cantidad) FROM Rubro r2
	JOIN Producto p2 ON p2.prod_rubro = r2.rubr_id
	JOIN Item_Factura i2 ON i2.item_producto = p2.prod_codigo
	WHERE r2.rubr_id = r.rubr_id), 0) as [Ventas del rubro],

	ISNULL((SELECT TOP 1 p2.prod_codigo  FROM Rubro r2 
	JOIN Producto p2 ON p2.prod_rubro = r2.rubr_id
	JOIN Item_Factura i2 ON i2.item_producto = p2.prod_codigo
	WHERE r2.rubr_id = r.rubr_id GROUP BY p2.prod_codigo
	ORDER BY SUM(i2.item_cantidad) DESC), 'SIN VENTAS') as [Prod m�s vendido],

	ISNULL((SELECT TOP 1 p2.prod_codigo FROM Rubro r2
	JOIN Producto p2 ON p2.prod_rubro = r2.rubr_id
	JOIN Item_Factura i2 ON i2.item_producto = p2.prod_codigo
	WHERE r2.rubr_id = r.rubr_id AND p2.prod_codigo != (SELECT TOP 1 p3.prod_codigo FROM Rubro r3 
														JOIN Producto p3 ON p3.prod_rubro = r.rubr_id
														JOIN Item_Factura i3 ON i3.item_producto = p3.prod_codigo
														WHERE r3.rubr_id = r2.rubr_id
														GROUP BY p3.prod_codigo ORDER BY SUM(i3.item_cantidad) DESC)
	GROUP BY p2.prod_codigo ORDER BY SUM(i2.item_cantidad) DESC), 'SIN VENTAS') as [Segundo producto m�s vendido],

	ISNULL((SELECT TOP 1 c2.clie_codigo FROM Cliente c2
	JOIN Factura f2 ON f2.fact_cliente = c2.clie_codigo
	JOIN Item_Factura i2 ON f2.fact_tipo+f2.fact_sucursal+f2.fact_numero = i2.item_tipo+i2.item_sucursal+i2.item_numero
	JOIN Producto p2 ON i2.item_producto = p2.prod_codigo
	JOIN Rubro r2 ON p2.prod_rubro = r2.rubr_id
	WHERE f2.fact_fecha BETWEEN (SELECT TOP 1 DATEADD(day, -30, f3.fact_fecha) FROM Factura f3 ORDER BY f3.fact_fecha DESC)
				   AND (SELECT TOP 1 f3.fact_fecha FROM Factura f3 ORDER BY f3.fact_fecha DESC) 
		 AND r2.rubr_id = r.rubr_id
	GROUP BY c2.clie_codigo, r2.rubr_detalle ORDER BY SUM(i2.item_cantidad) DESC), 'SIN VENTAS') as [Cliente que m�s compr� en los �ltimos 30 d�as]
FROM Rubro r
ORDER BY (SELECT COUNT(DISTINCT p2.prod_detalle)
		From Rubro r2
		JOIN Producto p2 ON p2.prod_rubro = r2.rubr_id
		JOIN Item_Factura i2 ON i2.item_producto = p2.prod_codigo
		WHERE r2.rubr_id = r.rubr_id) DESC

--Total ventas del rubro en pesos
SELECT SUM(i2.item_precio * i2.item_cantidad)
FROM Rubro r2
JOIN Producto p2 ON p2.prod_rubro = r2.rubr_id
JOIN Item_Factura i2 ON i2.item_producto = p2.prod_codigo
WHERE r2.rubr_id = '0025'

--Producto mas vendido
SELECT TOP 1 p.prod_codigo 
FROM Rubro r 
JOIN Producto p ON p.prod_rubro = r.rubr_id
JOIN Item_Factura i ON i.item_producto = p.prod_codigo
WHERE r.rubr_detalle = 'PILAS'
GROUP BY p.prod_codigo
ORDER BY SUM(i.item_cantidad) DESC

--Segundo producto mas vendido
SELECT TOP 1 p.prod_codigo 
FROM Rubro r 
JOIN Producto p ON p.prod_rubro = r.rubr_id
JOIN Item_Factura i ON i.item_producto = p.prod_codigo
WHERE r.rubr_detalle = 'PILAS' AND p.prod_codigo != (SELECT TOP 1 p.prod_codigo 
													FROM Rubro r 
													JOIN Producto p ON p.prod_rubro = r.rubr_id
													JOIN Item_Factura i ON i.item_producto = p.prod_codigo
													WHERE r.rubr_detalle = 'PILAS'
													GROUP BY p.prod_codigo
													ORDER BY SUM(i.item_cantidad) DESC)
GROUP BY p.prod_codigo
ORDER BY SUM(i.item_cantidad) DESC

--Cliente que mas compro del rubro en los ultimos 30 dias (Se toma como �ltimos 30 d�as a los �ltimos d�as facturados de la base de datos)
SELECT TOP 1 c.clie_codigo, r.rubr_detalle, SUM(i.item_cantidad)
FROM Cliente c
JOIN Factura f ON f.fact_cliente = c.clie_codigo
JOIN Item_Factura i ON f.fact_tipo+f.fact_sucursal+f.fact_numero = i.item_tipo+i.item_sucursal+i.item_numero
JOIN Producto p ON i.item_producto = p.prod_codigo
JOIN Rubro r ON p.prod_rubro = r.rubr_id
WHERE f.fact_fecha BETWEEN (SELECT TOP 1 DATEADD(day, -30, f2.fact_fecha) FROM Factura f2 ORDER BY f2.fact_fecha DESC)
				   AND (SELECT TOP 1 f2.fact_fecha FROM Factura f2 ORDER BY f2.fact_fecha DESC) AND r.rubr_detalle = 'PILAS'
GROUP BY c.clie_codigo, r.rubr_detalle
ORDER BY SUM(i.item_cantidad) DESC

--Prueba de DATEADD
SELECT TOP 1 f.fact_fecha, DATEADD(day, -30, f.fact_fecha)
FROM Factura f
ORDER BY f.fact_fecha DESC

SELECT f.fact_fecha
FROM Factura f
WHERE f.fact_fecha BETWEEN (SELECT TOP 1 DATEADD(day, -30, f2.fact_fecha) FROM Factura f2 ORDER BY f2.fact_fecha DESC) 
				   AND (SELECT TOP 1 f2.fact_fecha FROM Factura f2 ORDER BY f2.fact_fecha DESC) 
ORDER BY f.fact_fecha DESC

--ORDER BY 
SELECT COUNT(DISTINCT P.prod_detalle)
From Rubro r
JOIN Producto p ON p.prod_rubro = r.rubr_id
JOIN Item_Factura i ON i.item_producto = p.prod_codigo
WHERE r.rubr_detalle = 'PILAS'


/*19. En virtud de una recategorizacion de productos referida a la familia de los mismos se solicita
que desarrolle una consulta sql que retorne para todos los productos:

  -Codigo de producto
  -Detalle del producto
  -Codigo de la familia del producto
  -Detalle de la familia actual del producto
  -Codigo de la familia sugerido para el producto
  -Detalla de la familia sugerido para el producto

La familia sugerida para un producto es la que poseen la mayoria de los productos cuyo
detalle coinciden en los primeros 5 caracteres.

En caso que 2 o mas familias pudieran ser sugeridas se debera seleccionar la de menor codigo. 
Solo se deben mostrar los productos para los cuales la familia actual sea diferente a la sugerida.

Los resultados deben ser ordenados por detalle de producto de manera ascendente*/--Hecho en clase

SELECT p.prod_codigo [codigo producto], p.prod_detalle [detalle producto], f.fami_id [codigo familia], f.fami_detalle [detalle familia],
	(SELECT TOP 1 f2.fami_id FROM Producto P2 INNER JOIN Familia F2 on p2.prod_familia = f2.fami_id
	WHERE f2.fami_detalle != 'SIN ASIGNACION' AND SUBSTRING(p.prod_detalle, 1, 5) = SUBSTRING(p2.prod_detalle, 1, 5)
	GROUP BY f2.fami_id ORDER BY COUNT(*) DESC, f2.fami_id) [codigo familia sugerida],
	(SELECT TOP 1 f2.fami_detalle FROM Producto p2 INNER JOIN Familia f2 on p2.prod_familia = f2.fami_id
	WHERE f2.fami_detalle!= 'SIN ASIGNACION' AND SUBSTRING(p.prod_detalle, 1, 5) = SUBSTRING(p2.prod_detalle, 1, 5)
	GROUP BY f2.fami_id, f2.fami_detalle 
	ORDER BY COUNT(*) DESC, f2.fami_id)[detalle familia sugerida]
FROM Producto p
INNER JOIN Familia f on  p.prod_familia = f.fami_id
WHERE f.fami_detalle != 'SIN ASIGNACION' 
AND f.fami_id != (SELECT TOP 1 f2.fami_id FROM Producto p2 INNER JOIN Familia f2 on p2.prod_familia = f2.fami_id
				WHERE f2.fami_detalle != 'SIN ASIGNACION' AND SUBSTRING(p.prod_detalle, 1, 5) = SUBSTRING(p2.prod_detalle, 1, 5)
				GROUP BY f2.fami_id 
				ORDER BY COUNT (*) DESC)
ORDER BY p.prod_detalle

/*20. Escriba una consulta sql que retorne un ranking de los mejores 3 empleados del 2012

Se debera retornar legajo, nombre y apellido, anio de ingreso, puntaje 2011, puntaje 2012. El puntaje
de cada empleado se calculara de la siguiente manera: para los que hayan vendido al menos 50 facturas
el puntaje se calculara como la cantidad de facturas que superen los 100 pesos que haya vendido en el 
a�o, para los que tengan menos de 50 facturas en el a�o el calculo del puntaje sera el 50% de cantidad 
de facturas realizadas por sus subordinados directos en dicho a�o.*/ --Hecho en clase

SELECT TOP 3 e.empl_codigo as Legajo, e.empl_apellido as Apellido, e.empl_nombre as Nombre, YEAR(e.empl_ingreso) as [A�o de ingreso],
		CASE WHEN COUNT(DISTINCT f2011.fact_tipo+f2011.fact_sucursal+f2011.fact_numero) > 50 
		THEN (SELECT COUNT(*) FROM Factura WHERE YEAR(fact_fecha) = 2011 AND fact_total > 100 AND fact_vendedor = e.empl_codigo)
		ELSE (SELECT COUNT(*) / 2 FROM Factura WHERE YEAR(fact_fecha) = 2011 AND fact_vendedor in (SELECT empl_codigo FROM Empleado WHERE empl_jefe = empl_codigo)) 
		END as [Puntaje 2011],
		CASE WHEN COUNT(DISTINCT f2012.fact_tipo+f2012.fact_sucursal+f2012.fact_numero) > 50 
		THEN (SELECT COUNT(*) FROM Factura WHERE YEAR(fact_fecha) = 2012 AND fact_total > 100 AND fact_vendedor = e.empl_codigo)
		ELSE (SELECT COUNT(*) / 2 FROM Factura WHERE YEAR(fact_fecha) = 2012 AND fact_vendedor in (SELECT empl_codigo FROM Empleado WHERE empl_jefe = empl_codigo)) 
		END as [Puntaje 2012]
FROM Empleado e
LEFT JOIN Factura f2011 on e.empl_codigo = f2011.fact_vendedor AND YEAR(f2011.fact_fecha) = 2011
LEFT JOIN Factura f2012 on e.empl_codigo = f2012.fact_vendedor AND YEAR(f2012.fact_fecha) = 2012
GROUP BY e.empl_codigo, e.empl_apellido, e.empl_nombre, YEAR(e.empl_ingreso)
ORDER BY 6 DESC

--EL RESULTADO DEL PROFE DA OTRA COSA


/*21. Escriba una consulta sql que retorne para todos los a�os, en los cuales se haya hecho al menos
una factura, la cantidad de clientes a los que se les facturo de manera incorrecta al menos una factura
y que cantidad de facturas se realizaron de manera incorrecta. Se considera que una factura es incorrecta
cuando la diferencia entre el total de la factura menos el total de impuesto tiene una diferencia  mayor 
a $ 1 respecto a la sumatoria de los costos de cada uno de los items de dicha factura. Las columnas que se 
deben mostrar son:

  -A�o
  -Clientes a los que se les facturo mal en ese a�o
  -Facturas mal realizadas en ese a�o*/ --Hecho en clase

SELECT YEAR(f.fact_fecha),
	(SELECT COUNT (DISTINCT f2.fact_cliente) FROM Factura f2
	INNER JOIN Item_Factura i2 on  f2.fact_tipo+f2.fact_sucursal+f2.fact_numero = i2.item_tipo+i2.item_sucursal+i2.item_numero
	WHERE YEAR(f2.fact_fecha) = YEAR(f.fact_fecha)
	AND ((f2.fact_total - f2.fact_total_impuestos) - (SELECT SUM(i2.item_cantidad * i2.item_precio) 
													FROM Item_Factura I2 
													WHERE f2.fact_tipo+f2.fact_sucursal+f2.fact_numero = i2.item_tipo+i2.item_sucursal+i2.item_numero)
													NOT BETWEEN -1 AND 1)) as [Clientes mal facturados],

	(SELECT COUNT (DISTINCT f2.fact_tipo+f2.fact_sucursal+f2.fact_numero) FROM Factura f2
	INNER JOIN Item_Factura i2 on  f2.fact_tipo+f2.fact_sucursal+f2.fact_numero = i2.item_tipo+i2.item_sucursal+i2.item_numero
	WHERE YEAR(f2.fact_fecha) = YEAR(f.fact_fecha)
	AND ((f2.fact_total - f2.fact_total_impuestos) - (SELECT SUM(i2.item_cantidad * i2.item_precio) 
													FROM Item_Factura I2 
													WHERE f2.fact_tipo+f2.fact_sucursal+f2.fact_numero = i2.item_tipo+i2.item_sucursal+i2.item_numero)
													NOT BETWEEN -1 AND 1)) as [Facturas mal realizadas]
FROM Factura f
GROUP BY YEAR(f.fact_fecha)
ORDER BY 1

--El del profe ejecuta m�s r�pido

/*22. Escriba una consulta sql que retorne una estadistica de venta para todos los rubros por trimestre 
contabilizando todos los a�os. Se mostraran como maximo 4 filas por rubro (1 por cada trimestre).

Se deben mostrar 4 columnas:

  -Detalle del rubro
  -Numero de trimestre del a�o (1 a 4)
  -Cantidad de facturas emitidas en el trimestre en las que se haya vendido al menos un producto del rubro
  -Cantidad de productos diferentes del rubro vendidos en el trimestre

El resultado debe ser ordenado alfabeticamente por el detalle del rubro y dentro de cada rubro primero
el trimestre en el que mas facturas se emitieron.
No se deberan mostrar aquellos rubros y trimestres para los cuales las facturas emitidas no superen las 100.
En ningun momento se tendran en cuenta los productos compuestos para esta estadistica.*/

/*Interpret� que en la tercera columna se realiza el COUNT solo sobre las facturas que tienen al menos un producto de ese rubro.
Si fueran todas las facturas del trimestre (para todos los rubros) lo resolver�a con
(SELECT COUNT(*) FROM Factura f2 WHERE DATEPART(QUARTER, f.fact_fecha) = DATEPART(QUARTER, f2.fact_fecha))  */

SELECT r.rubr_detalle, DATEPART(QUARTER, f.fact_fecha) as [Trimestre],
	 COUNT(f.fact_tipo+f.fact_sucursal+f.fact_numero) as [Facturas del trimestre],
	 (SELECT COUNT(DISTINCT i2.item_producto) FROM Item_Factura i2 JOIN Producto p2 ON i2.item_producto = p2.prod_codigo 
	  JOIN Factura f2 on f2.fact_tipo+f2.fact_sucursal+f2.fact_numero = i2.item_tipo+i2.item_sucursal+i2.item_numero
	  WHERE p2.prod_rubro = r.rubr_id AND DATEPART(QUARTER, f.fact_fecha) = DATEPART(QUARTER, f2.fact_fecha)) as [Productos distintos del trimestre]
FROM Rubro r
JOIN Producto p ON p.prod_rubro = r.rubr_id
JOIN Item_Factura i ON p.prod_codigo = i.item_producto
JOIN Factura f ON f.fact_tipo+f.fact_sucursal+f.fact_numero = i.item_tipo+i.item_sucursal+i.item_numero
GROUP BY r.rubr_id, r.rubr_detalle, DATEPART(QUARTER, f.fact_fecha)
HAVING COUNT(f.fact_tipo+f.fact_sucursal+f.fact_numero) > 100
ORDER BY r.rubr_detalle, 3 DESC


/*23. Realizar una consulta SQL que para cada a�o muestre :

  -A�o
  -El producto con composici�n m�s vendido para ese a�o.
  -Cantidad de productos que componen directamente al producto m�s vendido
  -La cantidad de facturas en las cuales aparece ese producto.
  -El c�digo de cliente que m�s compro ese producto.
  -El porcentaje que representa la venta de ese producto respecto al total de venta del a�o.

El resultado deber� ser ordenado por el total vendido por a�o en forma descendente.*/--Hecho en clase

SELECT YEAR(f.fact_fecha) as [A�o] , i.item_producto as [Producto m�s vendido],
		(SELECT SUM(c2.comp_cantidad) FROM Composicion c2 WHERE c2.comp_producto = i.item_producto) as [Cantidad componentes],
		COUNT(DISTINCT f.fact_tipo+f.fact_sucursal+f.fact_numero) as [Cantidad de facturas],
		(SELECT TOP 1 f2.fact_cliente FROM Factura f2
		INNER JOIN Item_Factura i2 on f2.fact_tipo+f2.fact_sucursal+f2.fact_numero = i2.item_tipo+i2.item_sucursal+i2.item_numero
		WHERE YEAR(f.fact_fecha) = YEAR(f2.fact_fecha) AND i.item_producto = i2.item_producto
		GROUP BY f2.fact_cliente ORDER BY SUM(i2.item_cantidad) DESC) as [Cliente que m�s compr�],
		((SELECT SUM(i2.item_cantidad) FROM Item_Factura i2
		INNER JOIN Factura f2 on f2.fact_tipo+f2.fact_sucursal+f2.fact_numero = i2.item_tipo+i2.item_sucursal+i2.item_numero
		WHERE YEAR(f2.fact_fecha) = YEAR(f.fact_fecha) AND i2.item_producto = i.item_producto)* 100 /
		(SELECT SUM(i2.item_cantidad) FROM Item_Factura i2
		INNER JOIN Factura f2 on f2.fact_tipo+f2.fact_sucursal+f2.fact_numero = i2.item_tipo+i2.item_sucursal+i2.item_numero
		WHERE YEAR(f2.fact_fecha) = YEAR(f.fact_fecha))) as [Porcentaje respecto al total]
FROM Factura f
INNER JOIN Item_Factura i on f.fact_tipo+f.fact_sucursal+f.fact_numero = i.item_tipo+i.item_sucursal+i.item_numero
INNER JOIN Composicion c ON i.item_producto = c.comp_producto
WHERE i.item_producto = (SELECT TOP 1 i2.item_producto FROM Factura f2
						INNER JOIN Item_Factura i2 on f2.fact_tipo+f2.fact_sucursal+f2.fact_numero = i2.item_tipo+i2.item_sucursal+i2.item_numero
						INNER JOIN Composicion c2 ON i2.item_producto = c2.comp_producto
						WHERE YEAR(f.fact_fecha) = YEAR(f2.fact_fecha)
						GROUP BY i2.item_producto
						ORDER BY SUM(i2.item_cantidad) DESC)
GROUP BY YEAR(f.fact_fecha), i.item_producto
ORDER BY (SELECT SUM(i2.item_cantidad) FROM Item_Factura i2
		 INNER JOIN Factura f2 on f2.fact_tipo+f2.fact_sucursal+f2.fact_numero = i2.item_tipo+i2.item_sucursal+i2.item_numero
		 WHERE YEAR(f2.fact_fecha) = YEAR(f.fact_fecha))

/*24. Escriba una consulta que considerando solamente las facturas correspondientes a los dos vendedores
con mayores comisiones, retorne los productos con composici�n facturados al menos en cinco facturas,

La consulta debe retornar las siguientes columnas:

  -C�digo de Producto
  -Nombre del Producto
  -Unidades facturadas

El resultado deber� ser ordenado por las unidades facturadas descendente.*/

SELECT p.prod_codigo as [C�digo], p.prod_detalle as [Detalle], SUM(i.item_cantidad) as [Unidades vendidas]
FROM Producto p 
JOIN Item_Factura i ON i.item_producto = p.prod_codigo
JOIN Factura f ON i.item_numero+i.item_sucursal+i.item_tipo = f.fact_numero+f.fact_sucursal+f.fact_tipo
WHERE p.prod_codigo IN (SELECT DISTINCT c.comp_producto FROM Composicion c) 
	  AND f.fact_vendedor IN (SELECT TOP 2 empl_codigo FROM Empleado ORDER BY empl_comision DESC)
GROUP BY p.prod_codigo, p.prod_detalle
HAVING COUNT(DISTINCT i.item_numero+i.item_tipo+i.item_sucursal) > 5
ORDER BY [Unidades vendidas] DESC


/*25. Realizar una consulta SQL que para cada a�o y familia muestre:
  
  -A�o
  -El c�digo de la familia m�s vendida en ese a�o.
  -Cantidad de Rubros que componen esa familia.
  -Cantidad de productos que componen directamente al producto m�s vendido de esa familia.
  -La cantidad de facturas en las cuales aparecen productos pertenecientes a esa familia.
  -El c�digo de cliente que m�s compro productos de esa familia.
  -El porcentaje que representa la venta de esa familia respecto al total de venta del a�o.

El resultado deber� ser ordenado por el total vendido por a�o y familia en forma descendente.*/

SELECT YEAR(f.fact_fecha), flia.fami_id as [Familia m�s vendida],

		(SELECT COUNT(DISTINCT r2.rubr_id) FROM Rubro r2
		JOIN Producto p2 ON r2.rubr_id = p2.prod_rubro JOIN Familia flia2 ON flia2.fami_id = p2.prod_familia
		WHERE flia2.fami_id = flia.fami_id ) as [Cantidad de rubros],

		(SELECT COUNT(c.comp_componente) FROM Composicion c
		WHERE c.comp_producto = (SELECT TOP 1 p2.prod_codigo FROM Familia flia2
						JOIN Producto p2 ON p2.prod_familia = flia2.fami_id JOIN Item_factura i2 ON p2.prod_codigo = i2.item_producto
						WHERE flia2.fami_id = flia.fami_id GROUP BY p2.prod_codigo
						ORDER BY SUM(i2.item_cantidad) DESC)) as [Cantidad de productos],

		COUNT(DISTINCT f.fact_numero+f.fact_tipo+fact_sucursal) as [Cantidad de facturas de ese a�o],

		(SELECT TOP 1 f2.fact_cliente FROM Factura f2
		JOIN Item_Factura i2 ON i2.item_numero+i2.item_sucursal+i2.item_tipo = f2.fact_numero+f2.fact_sucursal+f2.fact_tipo
		JOIN Producto p2 ON p2.prod_codigo = i2.item_producto JOIN Familia flia2 ON p2.prod_familia = flia2.fami_id
		WHERE flia2.fami_id = flia.fami_id AND YEAR(f2.fact_fecha) = YEAR(f.fact_fecha)
		GROUP BY f2.fact_numero, f2.fact_sucursal, f2.fact_tipo, f2.fact_cliente
		ORDER BY COUNT(i2.item_cantidad) DESC) as [Cliente que m�s compr� ese a�o],

		(SUM(i.item_cantidad) * 100 / (SELECT SUM(i2.item_cantidad) FROM Factura f2
		JOIN Item_Factura i2 ON i2.item_numero+i2.item_sucursal+i2.item_tipo = f2.fact_numero+f2.fact_sucursal+f2.fact_tipo
		JOIN Producto p2 ON p2.prod_codigo = i2.item_producto JOIN Familia flia2 ON p2.prod_familia = flia2.fami_id
		WHERE YEAR(f2.fact_fecha) = YEAR(f.fact_fecha))) as [Porcentaje de ventas]

FROM Factura f
JOIN Item_Factura i ON i.item_numero+i.item_sucursal+i.item_tipo = f.fact_numero+f.fact_sucursal+f.fact_tipo
JOIN Producto p ON p.prod_codigo = i.item_producto JOIN Familia flia ON p.prod_familia = flia.fami_id
--Si calculo la flia m�s vendida del a�o en el where me tarda 3 minutos en ejecutar 
--Si la calculo en un subselect en la 2da columna me toma 0 seguntos pero despu�s no tengo como poner el id de esa familia en otros subselects
WHERE flia.fami_id IN (SELECT TOP 1 flia2.fami_id FROM Familia flia2
		JOIN Producto p2 ON p2.prod_familia = flia2.fami_id JOIN Item_Factura i2 ON i2.item_producto = p2.prod_codigo
		JOIN Factura f2 ON i2.item_numero+i2.item_sucursal+i2.item_tipo = f2.fact_numero+f2.fact_sucursal+f2.fact_tipo
		WHERE YEAR(f2.fact_fecha) = YEAR(f.fact_fecha)
		GROUP BY flia2.fami_id
		ORDER BY COUNT(i2.item_producto) DESC)
GROUP BY YEAR(f.fact_fecha), flia.fami_id
ORDER BY (SELECT SUM(i2.item_cantidad) FROM Factura f2
		JOIN Item_Factura i2 ON i2.item_numero+i2.item_sucursal+i2.item_tipo = f2.fact_numero+f2.fact_sucursal+f2.fact_tipo
		JOIN Producto p2 ON p2.prod_codigo = i2.item_producto JOIN Familia flia2 ON p2.prod_familia = flia2.fami_id
		WHERE YEAR(f2.fact_fecha) = YEAR(f.fact_fecha)) DESC, flia.fami_id DESC





/*26. Escriba una consulta sql que retorne un ranking de empleados devolviendo las siguientes columnas:
  
  -Empleado
  -Dep�sitos que tiene a cargo
  -Monto total facturado en el a�o corriente
  -Codigo de Cliente al que mas le vendi�
  -Producto m�s vendido
  -Porcentaje de la venta de ese empleado sobre el total vendido ese a�o.

Los datos deberan ser ordenados por venta del empleado de mayor a menor.*/

SELECT e.empl_codigo as [C�digo], CONCAT(RTRIM(e.empl_apellido),', ', RTRIM(e.empl_nombre)) AS [Empleado],
	
	(SELECT COUNT (*) FROM DEPOSITO d WHERE d.depo_encargado = e.empl_codigo) as [Dep�sitos a cargo],

	SUM(f.fact_total) as [Total facturado en el a�o],

	(SELECT TOP 1 f2.fact_cliente FROM Factura f2 
	JOIN Item_Factura i2 ON i2.item_numero+i2.item_sucursal+i2.item_tipo = f2.fact_numero+f2.fact_sucursal+f2.fact_tipo
	WHERE f2.fact_vendedor = e.empl_codigo
	GROUP BY f2.fact_cliente ORDER BY SUM(i2.item_cantidad) DESC) as [Cliente al que m�s vendi�],

	(SELECT TOP 1 i2.item_producto FROM Factura f2 
	JOIN Item_Factura i2 ON i2.item_numero+i2.item_sucursal+i2.item_tipo = f2.fact_numero+f2.fact_sucursal+f2.fact_tipo
	WHERE f2.fact_vendedor = e.empl_codigo
	GROUP BY i2.item_producto ORDER BY SUM(i2.item_cantidad) DESC ) as [Producto m�s vendido],
	
	SUM(f.fact_total) * 100 /  (SELECT SUM(f2.fact_total) FROM Factura f2
								WHERE YEAR(f2.fact_fecha) = 2012 --YEAR(GETDATE())
	) as [Porcentaje de ventas]
	
FROM Empleado e
LEFT JOIN Factura f ON e.empl_codigo = f.fact_vendedor 
WHERE YEAR(f.fact_fecha) = 2012 --YEAR(GETDATE())
GROUP BY e.empl_codigo, CONCAT(RTRIM(e.empl_apellido),', ', RTRIM(e.empl_nombre))
ORDER BY [Total facturado en el a�o] DESC


/*27. Escriba una consulta sql que retorne una estad�stica basada en la facturacion por a�o y envase 
devolviendo las siguientes columnas:

  -A�o
  -Codigo de envase
  -Detalle del envase
  -Cantidad de productos que tienen ese envase
  -Cantidad de productos facturados de ese envase
  -Producto mas vendido de ese envase
  -Monto total de venta de ese envase en ese a�o
  -Porcentaje de la venta de ese envase respecto al total vendido de ese a�o

Los datos deberan ser ordenados por a�o y dentro del a�o por el envase con m�s
facturaci�n de mayor a menor*/

SELECT YEAR(f.fact_fecha) as [A�o], en.enva_codigo as [C�digo envase], en.enva_detalle as [Detalle],

		(SELECT COUNT(*) FROM Producto p2 WHERE p2.prod_envase = en.enva_codigo) as [Productos con este envase],
		 
		(SELECT SUM(i2.item_cantidad) FROM Producto p2 
		JOIN Item_Factura i2 ON p2.prod_codigo = i2.item_producto
		WHERE p2.prod_envase = en.enva_codigo) as [Productos facturados],

		(SELECT TOP 1 i2.item_producto FROM Producto p2
		JOIN Item_Factura i2 ON p2.prod_codigo = i2.item_producto
		WHERE p2.prod_envase = en.enva_codigo
		GROUP BY i2.item_producto ORDER BY SUM(i2.item_cantidad) DESC) as [Producto m�s vendido],

	    SUM(f.fact_total) as [Venta total del a�o],

		SUM(f.fact_total) * 100 / (SELECT SUM(f2.fact_total) FROM Factura f2
								JOIN Item_Factura i2 ON i2.item_numero+i2.item_sucursal+i2.item_tipo = f2.fact_numero+f2.fact_sucursal+f2.fact_tipo
								JOIN Producto p2 ON p2.prod_codigo = i2.item_producto
								WHERE YEAR(f2.fact_fecha) = YEAR(f.fact_fecha)) as [Porcentaje de ventas]
FROM Envases en
JOIN Producto p ON p.prod_envase = en.enva_codigo
JOIN Item_Factura i ON p.prod_codigo = i.item_producto
JOIN Factura f ON i.item_numero+i.item_sucursal+i.item_tipo = f.fact_numero+f.fact_sucursal+f.fact_tipo
GROUP BY YEAR(f.fact_fecha), en.enva_codigo, en.enva_detalle
ORDER BY YEAR(f.fact_fecha), [Venta total del a�o] DESC


/*28. Escriba una consulta sql que retorne una estad�stica por A�o y Vendedor que retorne las siguientes
columnas:

  -A�o.
  -Codigo de Vendedor
  -Detalle del Vendedor
  -Cantidad de facturas que realiz� en ese a�o
  -Cantidad de clientes a los cuales les vendi� en ese a�o.
  -Cantidad de productos facturados con composici�n en ese a�o
  -Cantidad de productos facturados sin composicion en ese a�o.
  -Monto total vendido por ese vendedor en ese a�o

Los datos deberan ser ordenados por a�o y dentro del a�o por el vendedor que haya
vendido mas productos diferentes de mayor a menor.*/


SELECT YEAR(f.fact_fecha) as [A�o], e.empl_codigo as [C�digo empleado], CONCAT(RTRIM(e.empl_apellido),', ', RTRIM(e.empl_nombre)) as [Empleado],
		COUNT(DISTINCT f.fact_numero+f.fact_sucursal+f.fact_tipo) as [Cantidad de facturas del a�o],
		COUNT(DISTINCT f.fact_cliente) as [Cantidad clientes],
		
		(SELECT ISNULL(SUM(i2.item_cantidad), 0) FROM Item_Factura i2
		JOIN Factura f2 ON i2.item_numero+i2.item_sucursal+i2.item_tipo = f2.fact_numero+f2.fact_sucursal+f2.fact_tipo
		WHERE i2.item_producto IN (SELECT c.comp_producto FROM Composicion c) AND f2.fact_vendedor = e.empl_codigo 
		AND YEAR(f.fact_fecha) = YEAR(f2.fact_fecha)) as [Con composici�n],
		
		(SELECT ISNULL(SUM(i2.item_cantidad), 0) FROM Item_Factura i2
		JOIN Factura f2 ON i2.item_numero+i2.item_sucursal+i2.item_tipo = f2.fact_numero+f2.fact_sucursal+f2.fact_tipo
		WHERE i2.item_producto NOT IN (SELECT c.comp_producto FROM Composicion c) AND f2.fact_vendedor = e.empl_codigo 
		AND YEAR(f.fact_fecha) = YEAR(f2.fact_fecha)) as [Sin composici�n],  
		
		SUM(f.fact_total) as [Total vendido]
FROM Empleado e
JOIN Factura f ON f.fact_vendedor = e.empl_codigo
JOIN Item_Factura i ON i.item_sucursal+i.item_numero+i.item_tipo = f.fact_sucursal+f.fact_numero+f.fact_tipo
JOIN Producto p ON p.prod_codigo = i.item_producto
GROUP BY YEAR(f.fact_fecha), e.empl_codigo, CONCAT(RTRIM(e.empl_apellido),', ', RTRIM(e.empl_nombre))
ORDER BY YEAR(f.fact_fecha), [Total vendido] DESC


/*29. Se solicita que realice una estad�stica de venta por producto para el a�o 2011, solo para los 
productos que pertenezcan a las familias que tengan m�s de 20 productos asignados a ellas, la cual 
deber� devolver las siguientes columnas:

  -C�digo de producto
  -Descripci�n del producto
  -Cantidad vendida
  -Cantidad de facturas en la que esta ese producto
  -Monto total facturado de ese producto

Solo se deber� mostrar un producto por fila en funci�n a los considerandos establecidos
antes. El resultado deber� ser ordenado por la cantidad vendida de mayor a menor.*/

SELECT p.prod_codigo as [C�digo producto], p.prod_detalle as [Descripci�n], ISNULL(SUM(i.item_cantidad), 0) AS [Cantidad vendida],
		COUNT(DISTINCT f.fact_numero+f.fact_sucursal+f.fact_tipo) as [Cantidad de facturas],
		ISNULL(SUM(f.fact_total), 0) as [Total facturado]
FROM Producto p JOIN Item_Factura i ON p.prod_codigo = i.item_producto
LEFT JOIN Factura f ON i.item_sucursal+i.item_numero+i.item_tipo = f.fact_sucursal+f.fact_numero+f.fact_tipo
WHERE YEAR(f.fact_fecha) = 2011 AND p.prod_familia IN (SELECT flia.fami_id FROM Producto p
													  JOIN Familia flia ON p.prod_familia = flia.fami_id
													  GROUP BY flia.fami_id
													  HAVING COUNT(DISTINCT p.prod_codigo) > 20)
GROUP BY p.prod_codigo, p.prod_detalle
ORDER BY [Cantidad vendida] DESC


/*30. Se desea obtener una estadistica de ventas del a�o 2012, para los empleados que sean jefes, 
o sea, que tengan empleados a su cargo, para ello se requiere que realice la consulta que retorne
 las siguientes columnas:

  -Nombre del Jefe
  -Cantidad de empleados a cargo
  -Monto total vendido de los empleados a cargo
  -Cantidad de facturas realizadas por los empleados a cargo
  -Nombre del empleado con mejor ventas de ese jefe

Debido a la perfomance requerida, solo se permite el uso de una subconsulta si fuese necesario.
Los datos deberan ser ordenados de mayor a menor por el Total vendido y solo se
deben mostrarse los jefes cuyos subordinados hayan realizado m�s de 10 facturas.*/

SELECT e.empl_codigo as [C�digo jefe], CONCAT(RTRIM(e.empl_apellido),', ', RTRIM(e.empl_nombre)) as [Nombre jefe],
		COUNT(DISTINCT e2.empl_codigo) as [Empleados a cargo],
	    ISNULL(SUM(f.fact_total), 0) as [Monto total vendido],
		COUNT(DISTINCT f.fact_numero+f.fact_sucursal+f.fact_tipo) as [Cantidad de facturas],

		(SELECT TOP 1 CONCAT(RTRIM(e3.empl_apellido),', ', RTRIM(e3.empl_nombre)) FROM Empleado e3
		JOIN Factura f2 ON f2.fact_vendedor = e3.empl_codigo
		WHERE e3.empl_jefe = e.empl_codigo
		GROUP BY CONCAT(RTRIM(e3.empl_apellido),', ', RTRIM(e3.empl_nombre))
		ORDER BY SUM(f2.fact_total) DESC) as [Mejor empleado]

FROM Empleado e
JOIN Empleado e2 ON e.empl_codigo = e2.empl_jefe
LEFT JOIN Factura f ON f.fact_vendedor = e2.empl_codigo
--Por qu� no aparece el jefe cod 2 si puse LEFT JOIN? No deber�a aparecer pero con las columnas en 0?
WHERE YEAR(f.fact_fecha) = 2012
GROUP BY e.empl_codigo, CONCAT(RTRIM(e.empl_apellido),', ', RTRIM(e.empl_nombre))
HAVING COUNT(DISTINCT f.fact_numero+f.fact_sucursal+f.fact_tipo) > 10
ORDER BY [Monto total vendido] DESC

/*31. Escriba una consulta sql que retorne una estad�stica por A�o y Vendedor que retorne las siguientes
columnas:

  -A�o.
  -Codigo de Vendedor
  -Detalle del Vendedor
  -Cantidad de facturas que realiz� en ese a�o
  -Cantidad de clientes a los cuales les vendi� en ese a�o.
  -Cantidad de productos facturados con composici�n en ese a�o
  -Cantidad de productos facturados sin composicion en ese a�o.
  -Monto total vendido por ese vendedor en ese a�o

Los datos deberan ser ordenados por a�o y dentro del a�o por el vendedor que haya
vendido mas productos diferentes de mayor a menor.*/

SELECT YEAR(f.fact_fecha) as [A�o], e.empl_codigo as [C�digo empleado], CONCAT(RTRIM(e.empl_apellido),', ', RTRIM(e.empl_nombre)) as [Empleado],
		COUNT(DISTINCT f.fact_numero+f.fact_sucursal+f.fact_tipo) as [Cantidad de facturas del a�o],
		COUNT(DISTINCT f.fact_cliente) as [Cantidad clientes],
		
		(SELECT ISNULL(SUM(i2.item_cantidad), 0) FROM Item_Factura i2
		JOIN Factura f2 ON i2.item_numero+i2.item_sucursal+i2.item_tipo = f2.fact_numero+f2.fact_sucursal+f2.fact_tipo
		WHERE i2.item_producto IN (SELECT c.comp_producto FROM Composicion c) AND f2.fact_vendedor = e.empl_codigo 
		AND YEAR(f.fact_fecha) = YEAR(f2.fact_fecha)) as [Con composici�n],
		
		(SELECT ISNULL(SUM(i2.item_cantidad), 0) FROM Item_Factura i2
		JOIN Factura f2 ON i2.item_numero+i2.item_sucursal+i2.item_tipo = f2.fact_numero+f2.fact_sucursal+f2.fact_tipo
		WHERE i2.item_producto NOT IN (SELECT c.comp_producto FROM Composicion c) AND f2.fact_vendedor = e.empl_codigo 
		AND YEAR(f.fact_fecha) = YEAR(f2.fact_fecha)) as [Sin composici�n],  
		
		SUM(f.fact_total) as [Total vendido]
FROM Empleado e
JOIN Factura f ON f.fact_vendedor = e.empl_codigo
JOIN Item_Factura i ON i.item_sucursal+i.item_numero+i.item_tipo = f.fact_sucursal+f.fact_numero+f.fact_tipo
JOIN Producto p ON p.prod_codigo = i.item_producto
GROUP BY YEAR(f.fact_fecha), e.empl_codigo, CONCAT(RTRIM(e.empl_apellido),', ', RTRIM(e.empl_nombre))
ORDER BY YEAR(f.fact_fecha), [Total vendido] DESC

/*32. Se desea conocer las familias que sus productos se facturaron juntos en las mismas facturas 
para ello se solicita que escriba una consulta sql que retorne los pares de familias que tienen 
productos que se facturaron juntos. Para ellos deber� devolver las siguientes columnas:

  -C�digo de familia
  -Detalle de familia
  -C�digo de familia
  -Detalle de familia
  -Cantidad de facturas
  -Total vendido

Los datos deberan ser ordenados por Total vendido y solo se deben mostrar las familias
que se vendieron juntas m�s de 10 veces.*/

SELECT * FROM Producto p
JOIN Item_Factura i ON i.item_producto = p.prod_codigo

/*33. Se requiere obtener una estad�stica de venta de productos que sean componentes. Para ello se 
solicita que se realice la siguiente consulta que retorne la venta de los componentes del producto m�s
vendido del a�o 2012. Se deber� mostrar:

  -C�digo de producto
  -Nombre del producto
  -Cantidad de unidades vendidas
  -Cantidad de facturas en la cual se facturo
  -Precio promedio facturado de ese producto.
  -Total facturado para ese producto

El resultado deber� ser ordenado por el total vendido por producto para el a�o 2012.*/

SELECT p.prod_codigo as [C�digo], p.prod_detalle [Nombre producto], SUM(i.item_cantidad) as [Unidades vendidas], 
		COUNT(DISTINCT f.fact_sucursal+f.fact_numero+f.fact_tipo) as [Cantidad de facturas],
		SUM(i.item_cantidad * i.item_precio) / SUM(i.item_cantidad) as [Precio promedio],
		SUM(i.item_cantidad * i.item_precio) as [Total facturado]
FROM Producto p
JOIN Item_Factura i ON p.prod_codigo = i.item_producto
JOIN Factura f ON i.item_sucursal+i.item_numero+i.item_tipo = f.fact_sucursal+f.fact_numero+f.fact_tipo
WHERE Year(f.fact_fecha) = 2012 AND p.prod_codigo IN (SELECT c2.comp_componente FROM Composicion c2
														WHERE c2.comp_producto = (SELECT TOP 1 i2.item_producto FROM Item_Factura i2 
																			   JOIN Factura f2 ON i2.item_sucursal+i2.item_numero+i2.item_tipo = f2.fact_sucursal+f2.fact_numero+f2.fact_tipo
																			   WHERE YEAR(f2.fact_fecha) = 2012 GROUP BY i2.item_producto
																			   ORDER BY SUM(i2.item_cantidad) DESC))
GROUP BY p.prod_codigo, p.prod_detalle
ORDER BY [Total facturado]

/*34. Escriba una consulta sql que retorne para todos los rubros la cantidad de facturas mal facturadas
por cada mes del a�o 2011. Se considera que una factura es incorrecta cuando en la misma factura se 
facturan productos de dos rubros diferentes. Si no hay facturas mal hechas se debe retornar 0. 
Las columnas que se deben mostrar son:

  -Codigo de Rubro
  -Mes
  -Cantidad de facturas mal realizadas.*/

  SELECT p.prod_rubro as [Rubro], MONTH(f.fact_fecha) as [Mes], COUNT(DISTINCT f.fact_sucursal+f.fact_numero+f.fact_tipo) as [Mal facturadas] 
  FROM Producto p 
  JOIN Item_factura i ON i.item_producto = p.prod_codigo
  JOIN Factura f ON i.item_sucursal+i.item_numero+i.item_tipo = f.fact_sucursal+f.fact_numero+f.fact_tipo
  WHERE YEAR(f.fact_fecha) = 2011 AND f.fact_sucursal+f.fact_numero+f.fact_tipo IN (SELECT f2.fact_sucursal+f2.fact_numero+f2.fact_tipo FROM Factura f2
										JOIN Item_Factura i2 ON i2.item_sucursal+i2.item_numero+i2.item_tipo = f2.fact_sucursal+f2.fact_numero+f2.fact_tipo
										JOIN Producto p2 ON p.prod_codigo = i2.item_producto WHERE MONTH(f.fact_fecha) = MONTH(f2.fact_fecha)
										GROUP BY f2.fact_sucursal+f2.fact_numero+f2.fact_tipo HAVING COUNT(DISTINCT p2.prod_rubro) > 1)
  GROUP BY p.prod_rubro, MONTH(f.fact_fecha)

/*35. Se requiere realizar una estad�stica de ventas por a�o y producto, para ello se solicita que 
escriba una consulta sql que retorne las siguientes columnas:

  -A�o
  -Codigo de producto
  -Detalle del producto
  -Cantidad de facturas emitidas a ese producto ese a�o
  -Cantidad de vendedores diferentes que compraron ese producto ese a�o.
  -Cantidad de productos a los cuales compone ese producto, si no compone a ninguno se debera retornar 0.
  -Porcentaje de la venta de ese producto respecto a la venta total de ese a�o.

Los datos deberan ser ordenados por a�o y por producto con mayor cantidad vendida.*/

SELECT YEAR(f.fact_fecha) as [A�o], p.prod_codigo as [C�digo producto], p.prod_detalle as [Detalle producto], 
		COUNT(DISTINCT f.fact_sucursal+f.fact_numero+f.fact_tipo) as [Cantidad de facturas],
		COUNT(DISTINCT f.fact_cliente) as [Cantidad de clientes],
		(SELECT COUNT(c.comp_componente) FROM Composicion c WHERE c.comp_componente = p.prod_codigo) as [Productos que compone],
		SUM(i.item_cantidad * i.item_precio) * 100 / (SELECT SUM(f2.fact_total) FROM Factura f2
								WHERE YEAR(f2.fact_fecha) = YEAR(f.fact_fecha)) as [Porcentaje de ventas]
FROM Factura f
JOIN Item_Factura i ON i.item_sucursal+i.item_numero+i.item_tipo = f.fact_sucursal+f.fact_numero+f.fact_tipo
JOIN Producto p ON i.item_producto = p.prod_codigo
GROUP BY YEAR(f.fact_fecha), p.prod_codigo, p.prod_detalle
ORDER BY YEAR(f.fact_fecha), SUM(i.item_cantidad)

SELECT SUM(f2.fact_total) FROM Factura f2
								WHERE YEAR(f2.fact_fecha) = 2010


