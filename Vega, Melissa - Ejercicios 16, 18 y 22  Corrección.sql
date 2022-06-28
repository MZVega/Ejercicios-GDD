USE GDD2022C1
GO


-----------------------------------------------------------------------------------------------------------------------------------------------------
--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////--
-----------------------------------------------------------------------------------------------------------------------------------------------------

/*22. Escriba una consulta sql que retorne una estadistica de venta para todos los rubros por trimestre 
contabilizando todos los años. Se mostraran como maximo 4 filas por rubro (1 por cada trimestre).

Se deben mostrar 4 columnas:

  -Detalle del rubro
  -Numero de trimestre del año (1 a 4)
  -Cantidad de facturas emitidas en el trimestre en las que se haya vendido al menos un producto del rubro
  -Cantidad de productos diferentes del rubro vendidos en el trimestre

El resultado debe ser ordenado alfabeticamente por el detalle del rubro y dentro de cada rubro primero
el trimestre en el que mas facturas se emitieron.
No se deberan mostrar aquellos rubros y trimestres para los cuales las facturas emitidas no superen las 100.
En ningun momento se tendran en cuenta los productos compuestos para esta estadistica.*/

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
ORDER BY r.rubr_detalle, 3 DESC, 2

/* NO NECESITAS HACER UN SUBSELECT PORQUE LOS PRODUCTOS DISTINCTOS
 LOS PODES CALCULAR CON UN COUNT(DISTINCT) DE HECHO, EL COUNT QUE PUSISTE
 PARA LAS FACTURAS, TANTO EN LA LINEA DEL SELECT COMO EN EL HAVING ESTA MAL
 PORQUE LA ATOMICIDAD DE LA CONSULTA HACE QUE TE DEVUELVA CANTIDAD DE RENGLONES
 Y NO CANTIDAD DE FACTURAS 
 ACA TE LO PASO RESUELTO MAS SENCILLO Y SIN ESOS ERRORES */
 
SELECT r.rubr_detalle,
DATEPART(QUARTER, f.fact_fecha) as trimestre,
COUNT(DISTINCT item_numero+item_sucursal+item_tipo) as cant_facturas,
COUNT(DISTINCT prod_codigo) as cant_productos
FROM Producto p 
JOIN Rubro r ON r.rubr_id = p.prod_rubro
JOIN Item_Factura i ON i.item_producto = p.prod_codigo
JOIN Factura f ON f.fact_numero = i.item_numero AND f.fact_sucursal = i.item_sucursal AND f.fact_tipo = i.item_tipo
GROUP BY r.rubr_detalle, DATEPART(QUARTER, f.fact_fecha)
HAVING COUNT(DISTINCT item_numero+item_sucursal+item_tipo) > 100
ORDER BY r.rubr_detalle ASC, cant_facturas DESC, trimestre

 
-----------------------------------------------------------------------------------------------------------------------------------------------------
--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////--
-----------------------------------------------------------------------------------------------------------------------------------------------------


/*16. Con el fin de lanzar una nueva campaña comercial para los clientes que menos compran en la 
empresa, se pide una consulta SQL que retorne aquellos clientes cuyas ventas son inferiores a 1/3 del
promedio de ventas del producto que más se vendió en el 2012.

Además mostrar
  1. Nombre del Cliente
  2. Cantidad de unidades totales vendidas en el 2012 para ese cliente.
  3. Código de producto que mayor venta tuvo en el 2012 (en caso de existir más de 1, mostrar solamente
     el de menor código) para ese cliente.

Aclaraciones:
La composición es de 2 niveles, es decir, un producto compuesto solo se compone de productos no compuestos.
Los clientes deben ser ordenados por código de provincia ascendente.*/

--ENTIENDO QUE NO RETORNA VALORES PORQUE NINGUNO QUE CUMPLE CON LA CONDICIÓN
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
-- TE CAMBIE EL SUM(ITEM_CANTIDAD) POR AVG() PORQUE SI COMPARAS UNA SUMATORIA 
-- CONTRA UN AVG NUNCA TE VA A DAR 
HAVING AVG(i.item_cantidad) < ((SELECT AVG(i2.item_cantidad)
							 FROM Factura f2
							 INNER JOIN Item_Factura i2 ON f2.fact_tipo+f2.fact_sucursal+f2.fact_numero = i2.item_tipo+i2.item_sucursal+i2.item_numero
							 WHERE i2.item_producto = (SELECT TOP 1 i3.item_producto FROM Factura f3
													INNER JOIN Item_Factura i3 on f3.fact_tipo+f3.fact_sucursal+f3.fact_numero = i3.item_tipo+i3.item_sucursal+i3.item_numero
													WHERE YEAR(f3.fact_fecha) = 2012
													GROUP BY i3.item_producto
													ORDER BY SUM(i3.item_cantidad) DESC)) / 3) 



/*A PARTIR DE ACÁ SON LOS PASOS QUE FUI HACIENDO HASTA LLEGAR A LA CONSULTA PRINCIPAL*/
													
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


-----------------------------------------------------------------------------------------------------------------------------------------------------
--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////--
-----------------------------------------------------------------------------------------------------------------------------------------------------

/*18. Escriba una consulta que retorne una estadística de ventas para todos los rubros.

La consulta debe retornar:

  DETALLE_RUBRO: Detalle del rubro
  VENTAS: Suma de las ventas en pesos de productos vendidos de dicho rubro
  PROD1: Código del producto más vendido de dicho rubro
  PROD2: Código del segundo producto más vendido de dicho rubro
  CLIENTE: Código del cliente que compro más productos del rubro en los últimos 30 días

La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada
por cantidad de productos diferentes vendidos del rubro.*/
--Interpretaciones mías:
		--(Se toma como últimos 30 días a los últimos días facturados de la base de datos)


SELECT r.rubr_detalle as [Rubro],
	ISNULL((SELECT SUM(i2.item_precio * i2.item_cantidad) FROM Rubro r2
	JOIN Producto p2 ON p2.prod_rubro = r2.rubr_id
	JOIN Item_Factura i2 ON i2.item_producto = p2.prod_codigo
	WHERE r2.rubr_id = r.rubr_id), 0) as [Ventas del rubro],

	ISNULL((SELECT TOP 1 p2.prod_codigo  FROM Rubro r2 
	JOIN Producto p2 ON p2.prod_rubro = r2.rubr_id
	JOIN Item_Factura i2 ON i2.item_producto = p2.prod_codigo
	WHERE r2.rubr_id = r.rubr_id GROUP BY p2.prod_codigo
	ORDER BY SUM(i2.item_cantidad) DESC), 'SIN VENTAS') as [Prod más vendido],

	ISNULL((SELECT TOP 1 p2.prod_codigo FROM Rubro r2
	JOIN Producto p2 ON p2.prod_rubro = r2.rubr_id
	JOIN Item_Factura i2 ON i2.item_producto = p2.prod_codigo
	WHERE r2.rubr_id = r.rubr_id AND p2.prod_codigo != (SELECT TOP 1 p3.prod_codigo FROM Rubro r3 
														JOIN Producto p3 ON p3.prod_rubro = r.rubr_id
														JOIN Item_Factura i3 ON i3.item_producto = p3.prod_codigo
														WHERE r3.rubr_id = r2.rubr_id
														GROUP BY p3.prod_codigo ORDER BY SUM(i3.item_cantidad) DESC)
	GROUP BY p2.prod_codigo ORDER BY SUM(i2.item_cantidad) DESC), 'SIN VENTAS') as [Segundo producto más vendido],

	ISNULL((SELECT TOP 1 c2.clie_codigo FROM Cliente c2
	JOIN Factura f2 ON f2.fact_cliente = c2.clie_codigo
	JOIN Item_Factura i2 ON f2.fact_tipo+f2.fact_sucursal+f2.fact_numero = i2.item_tipo+i2.item_sucursal+i2.item_numero
	JOIN Producto p2 ON i2.item_producto = p2.prod_codigo
	JOIN Rubro r2 ON p2.prod_rubro = r2.rubr_id
	WHERE f2.fact_fecha BETWEEN (SELECT TOP 1 DATEADD(day, -30, f3.fact_fecha) FROM Factura f3 ORDER BY f3.fact_fecha DESC)
				   AND (SELECT TOP 1 f3.fact_fecha FROM Factura f3 ORDER BY f3.fact_fecha DESC) 
		 AND r2.rubr_id = r.rubr_id
	GROUP BY c2.clie_codigo, r2.rubr_detalle ORDER BY SUM(i2.item_cantidad) DESC), 'SIN VENTAS') as [Cliente que más compró en los últimos 30 días]
FROM Rubro r
ORDER BY (SELECT COUNT(DISTINCT p2.prod_detalle)
		From Rubro r2
		JOIN Producto p2 ON p2.prod_rubro = r2.rubr_id
		JOIN Item_Factura i2 ON i2.item_producto = p2.prod_codigo
		WHERE r2.rubr_id = r.rubr_id) DESC

/* LAS VENTAS LAS PODES CALCULAR EN EL SELECT PRINCIPAL Y ESO TE EVITA UNA 
SUBCONSULTA EN EL SELECT Y TAMBIEN EN EL ORDER BY, FIJATE TAMBIEN QUE EL
EL PRODUCTO MAS VENDIDO NO ES UN SUBSELECT LO CALCULO EN EL SELECT PRINCIPAL
FILTRANDOLO EN EL WHERE ACA TE LO PASO */

select rubr_detalle RUBRO, ISNULL(sum(item_precio*item_cantidad),0) CANTIDAD_VENDIDA, prod_codigo PRODUCTO_MAS_VENDIDO1,
		(select top 1 item_producto
		from Item_Factura join Producto P2 on P2.prod_codigo = item_producto 
		where p2.prod_rubro = rubr_id and item_producto <> (select top 1 item_producto from Item_Factura join Producto on prod_codigo = item_producto 
															where prod_rubro = rubr_id				
															group by item_producto
															order by sum(item_precio*item_cantidad) desc) 				
		group by item_producto
		order by sum(item_precio*item_cantidad) desc) PRODUCTO_MAS_VENDIDO2,

		(select top 1 fact_cliente from factura join item_factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
			where item_producto in (select prod_codigo from producto where prod_rubro = rubr_id)
			 AND fact_fecha > GETDATE() - 30
			group by fact_cliente
			order by sum(item_precio*item_cantidad) desc)  CLIENTE_MAS_COMPRO

from Rubro left join Producto on rubr_id = prod_rubro join Item_Factura on prod_codigo = item_producto
where prod_codigo in (select top 1 item_producto from Item_Factura join Producto on prod_codigo = item_producto 
						where prod_rubro = rubr_id				
						group by item_producto
						order by sum(item_precio*item_cantidad) desc)	
group by rubr_detalle, rubr_id, prod_codigo
order by count(distinct item_producto) 



/*A PARTIR DE ACÁ SON LOS PASOS QUE FUI HACIENDO HASTA LLEGAR A LA CONSULTA PRINCIPAL*/

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

--Cliente que mas compro del rubro en los ultimos 30 dias (Se toma como últimos 30 días a los últimos días facturados de la base de datos)
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