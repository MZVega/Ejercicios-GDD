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
HAVING COUNT(DISTINCT i.item_numero+i.item_tipo+i.item_sucursal) >= 5
ORDER BY [Unidades vendidas] DESC


-- ESTE ESTA BIEN LO UNICO QUE TE CAMBIE ES QUE ES MENOR O IGUAL QUE 5


-----------------------------------------------------------------------------------------------------------------------------------------------------
--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////--
-----------------------------------------------------------------------------------------------------------------------------------------------------

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

		COUNT(f.fact_numero+f.fact_tipo+fact_sucursal) as [Cantidad de facturas de ese a�o],

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



-- ESTE YA LO HICIMOS EN CLASE Y VIMOS JUNTOS LAS DIFERENCIAS

-----------------------------------------------------------------------------------------------------------------------------------------------------
--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////--
-----------------------------------------------------------------------------------------------------------------------------------------------------

/*26. Escriba una consulta sql que retorne un ranking de empleados devolviendo las siguientes columnas:
  
  -Empleado
  -Dep�sitos que tiene a cargo
  -Monto total facturado en el a�o corriente
  -Codigo de Cliente al que mas le vendi�
  -Producto m�s vendido
  -Porcentaje de la venta de ese empleado sobre el total vendido ese a�o.

Los datos deberan ser ordenados por venta del empleado de mayor a menor.*/

SELECT e.empl_codigo as [C�digo], RTRIM(e.empl_apellido)+' '+RTRIM(e.empl_nombre) AS [Empleado],
	
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
GROUP BY e.empl_codigo, RTRIM(e.empl_apellido)+' '+RTRIM(e.empl_nombre)
ORDER BY [Total facturado en el a�o] DESC


-- ESTA BIEN QUE LE PONGAS LEFT JOIN O JOIN EN ESTE CASO ES LO MISMO PORQUE
-- PORQUE AL FILTRAR POR FECHA EN EL WHERE CUANDO UN EMPLEADO NO TIENE VENTA
-- LA FECHA ESTA EN NULL POR LO TANTO NO TE LO TRAE

-----------------------------------------------------------------------------------------------------------------------------------------------------
--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////--
-----------------------------------------------------------------------------------------------------------------------------------------------------

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

	    SUM(item_precio*item_cantidad) as [Venta total del a�o],

		SUM(item_precio*item_cantidad) * 100 / (SELECT SUM(I2.item_precio*I2.item_cantidad) FROM Factura f2
								JOIN Item_Factura i2 ON i2.item_numero+i2.item_sucursal+i2.item_tipo = f2.fact_numero+f2.fact_sucursal+f2.fact_tipo
								JOIN Producto p2 ON p2.prod_codigo = i2.item_producto
								WHERE YEAR(f2.fact_fecha) = YEAR(f.fact_fecha)) as [Porcentaje de ventas]
FROM Envases en
JOIN Producto p ON p.prod_envase = en.enva_codigo
JOIN Item_Factura i ON p.prod_codigo = i.item_producto
JOIN Factura f ON i.item_numero+i.item_sucursal+i.item_tipo = f.fact_numero+f.fact_sucursal+f.fact_tipo
GROUP BY YEAR(f.fact_fecha), en.enva_codigo, en.enva_detalle
ORDER BY YEAR(f.fact_fecha), [Venta total del a�o] DESC

-- COMO LA ATOMICIDAD ESTA DADA POR ITEM EN LA SUMA TENES QUE PONER ITEM_PRECIO*ITEM_CANTIDAD
-- ESO TE LO CAMBIE EN LAS DOS ULTIMAS COLUMNAS, DESPUES CUANDO TOMAS LA VENTA 
-- TOTAL DEL ANO PASA LO MISMO POR ESO TE LO CAMBIE

-----------------------------------------------------------------------------------------------------------------------------------------------------
--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////--
-----------------------------------------------------------------------------------------------------------------------------------------------------

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


SELECT YEAR(f.fact_fecha) as [A�o], e.empl_codigo as [C�digo empleado], RTRIM(e.empl_apellido)+' '+RTRIM(e.empl_nombre) as [Empleado],
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
GROUP BY YEAR(f.fact_fecha), e.empl_codigo, RTRIM(e.empl_apellido)+' '+RTRIM(e.empl_nombre)
ORDER BY YEAR(f.fact_fecha), [Total vendido] DESC

-- ESTE ESTA BIEN, LO UNICO QUE YO ENTIENDO DIFERENTE ES LA CANTIDAD DE PRODUCTOS
-- CON Y SIN COMPOSICION PARA MI ES COUNT NO SUM CANTIDAD DE PRODUCTOS DISTINTOS
-- CON Y SIN COMPOSICION

-----------------------------------------------------------------------------------------------------------------------------------------------------
--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////--
-----------------------------------------------------------------------------------------------------------------------------------------------------

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
		ISNULL(SUM(I.item_precio*I.item_cantidad), 0) as [Total facturado]
FROM Producto p JOIN Item_Factura i ON p.prod_codigo = i.item_producto
LEFT JOIN Factura f ON i.item_sucursal+i.item_numero+i.item_tipo = f.fact_sucursal+f.fact_numero+f.fact_tipo
WHERE YEAR(f.fact_fecha) = 2011 AND p.prod_familia IN (SELECT flia.fami_id FROM Producto p
													  JOIN Familia flia ON p.prod_familia = flia.fami_id
													  GROUP BY flia.fami_id
													  HAVING COUNT(DISTINCT p.prod_codigo) > 20)
GROUP BY p.prod_codigo, p.prod_detalle
ORDER BY [Cantidad vendida] DESC

-- TE CAMBIE DE NUEVO EL SUM POR ITEM_PRECIO*ITEM_CANTIDAD POR LA ATOMICIDAD
-- OJO CON ESTO QUE TE PASA EN TODOS LOS EJERCICIOS Y ES GRAVE VOS TENES QUE 
-- VER CUAL ES LA TABLA QUE MANDA EN CANTIDAD EN EL QUERY PORQUE SINO LA SUMA 
-- ESTA MAL



-----------------------------------------------------------------------------------------------------------------------------------------------------
--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////--
-----------------------------------------------------------------------------------------------------------------------------------------------------

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

SELECT e.empl_codigo as [C�digo jefe], RTRIM(e.empl_apellido)+' '+RTRIM(e.empl_nombre) as [Nombre jefe],
		COUNT(DISTINCT e2.empl_codigo) as [Empleados a cargo],
	    ISNULL(SUM(f.fact_total), 0) as [Monto total vendido],
		COUNT(DISTINCT f.fact_numero+f.fact_sucursal+f.fact_tipo) as [Cantidad de facturas],

		(SELECT TOP 1 RTRIM(e3.empl_apellido)+' '+RTRIM(e3.empl_nombre) FROM Empleado e3
		JOIN Factura f2 ON f2.fact_vendedor = e3.empl_codigo
		WHERE e3.empl_jefe = e.empl_codigo
		GROUP BY RTRIM(e3.empl_apellido)+' '+RTRIM(e3.empl_nombre)
		ORDER BY SUM(f2.fact_total) DESC) as [Mejor empleado]

FROM Empleado e
JOIN Empleado e2 ON e.empl_codigo = e2.empl_jefe
LEFT JOIN Factura f ON f.fact_vendedor = e2.empl_codigo
--Por qu� no aparece el jefe cod 2 si puse LEFT JOIN? No deber�a aparecer pero con las columnas en 0?

-- COMO TE DIJE ANTES EN OTRO EKERCICIO NO TE APARECE PORQUE EN EL WHERE
-- FILTRAS POR FECHA Y COMO ES NULL NO LA TOMA

WHERE YEAR(f.fact_fecha) = 2012
GROUP BY e.empl_codigo, RTRIM(e.empl_apellido)+' '+RTRIM(e.empl_nombre)
HAVING COUNT(DISTINCT f.fact_numero+f.fact_sucursal+f.fact_tipo) > 10
ORDER BY [Monto total vendido] DESC

-- EL CONCAT SE LOS SAQUE PORQUE EL MOTOR QUE ESTOY USANDO ES MAS VIEJO
-- Y NO LO TIENE PERO ESTA BIEN EN TU CASO