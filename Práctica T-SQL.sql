/*-------------------------------------------------------------------------------------------------

                                         CLASE 24/05/2022

---------------------------------------------------------------------------------------------------*/

USE GDD2022C1
GO

/*1. Hacer una función que dado un artículo y un deposito devuelva un string que indique el estado del depósito según el artículo.
Si la cantidad almacenada es menor al límite retornar “OCUPACION DEL DEPOSITO XX %” siendo XX el % de ocupación. 
Si la cantidad almacenada es mayor o igual al límite retornar “DEPOSITO COMPLETO”.*/ --FUNCION

--SELECT s.*, dbo.fx_ejercicio1(stoc_producto, stoc_deposito)
--FROM STOCK s
--WHERE stoc_cantidad > 0 AND stoc_stock_maximo > 0

CREATE FUNCTION fx_ejercicio1 (@cod_articulo char(8), @cod_deposito char(2))
RETURNS VARCHAR(100) AS
BEGIN
DECLARE @RETORNO VARCHAR (100)
DECLARE @CANTIDAD DECIMAL (12, 2), @MAXIMO INT, @PORCENTAJE INT

SELECT @CANTIDAD = stoc_cantidad, @MAXIMO = stoc_stock_maximo
FROM STOCK s
WHERE stoc_producto = @cod_articulo AND stoc_deposito = @cod_deposito

IF @@ROWCOUNT = 0
	RETURN 'NO EXISTE EL PRODUCTO O EL DEPÓSITO, O NO HAY DE ESE PRODUCTO EN ESE DEPÓSITO'

IF @CANTIDAD >= @MAXIMO 
	RETURN 'DEPOSITO COMPLETO'

SET @PORCENTAJE = ROUND(@CANTIDAD * 100 / @MAXIMO, 0)
SET @RETORNO = CONCAT('OCUPACION DEL DEPOSITO ', @cod_deposito, ' ', @PORCENTAJE, '%')
	
RETURN @RETORNO 

END
GO

/*2. Realizar una función que dado un artículo y una fecha, retorne el stock que existía a esa fecha*/

CREATE FUNCTION fx_ejercicio_2 (@producto char(8), @fecha smalldatetime)
RETURNS decimal(12,2) AS
BEGIN

RETURN (SELECT SUM(stoc_cantidad) from STOCK where stoc_producto = @producto) 
		+
	   (SELECT SUM(item_cantidad) 
		from Item_Factura join Factura on item_tipo+item_numero+item_sucursal=fact_tipo+fact_numero+fact_sucursal
		WHERE fact_fecha >= @fecha and item_producto = @producto)

END
GO

/*3. Cree el/los objetos de base de datos necesarios para corregir la tabla empleado en caso que sea necesario.
Se sabe que debería existir un único gerente general (debería ser el único empleado sin jefe). 
Si detecta que hay más de un empleado sin jefe deberá elegir entre ellos el gerente general, el cual será seleccionado por mayor salario. 
Si hay más de uno se seleccionara el de mayor antigüedad en la empresa. 
Al finalizar la ejecución del objeto la tabla deberá cumplir con la regla de un único empleado sin jefe (el gerente general) y 
deberá retornar la cantidad de empleados que había sin jefe antes de la ejecución.*/ --STORE PROCEDURES / EJECUCION

/*4. Cree el/los objetos de base de datos necesarios para actualizar la columna de empleado empl_comision 
con la sumatoria del total de lo vendido por ese empleado a lo largo del último año. 
Se deberá retornar el código del vendedor que más vendió (en monto) a lo largo del último año.*/--STORE PROCEDURES / EJECUCION

/*5. Realizar un procedimiento que complete con los datos existentes en el modelo provisto la tabla de hechos denominada Fact_table 
tiene las siguiente definición:

Create table Fact_table
( anio char(4),
mes char(2),
familia char(3),
rubro char(4),
zona char(3),
cliente char(6),
producto char(8),
cantidad decimal(12,2),
monto decimal(12,2)
)
Alter table Fact_table
Add constraint primary key(anio,mes,familia,rubro,zona,cliente,producto)*/--STORE PROCEDURE + LLENADO DE LA TABLA


/*6. Realizar un procedimiento que si en alguna factura se facturaron componentes que conforman un combo determinado 
(o sea que juntos componen otro producto de mayor nivel), en cuyo caso deberá reemplazar las filas correspondientes a dichos productos 
por una sola fila con el producto que componen con la cantidad de dicho producto que corresponda.*/ -- Hecho en clase


CREATE PROCEDURE pr_ejercicio_6 AS
BEGIN
	DECLARE @tipo CHAR(1), @sucursal CHAR(4), @numero CHAR(8), @producto CHAR(8)
	DECLARE c_compuesto CURSOR FOR
	SELECT c.comp_producto, i.item_tipo, i.item_sucursal, i.item_numero
	FROM Composicion c
	INNER JOIN Item_Factura i on c.comp_componente = i.item_producto
	WHERE i.item_cantidad = c.comp_cantidad
	GROUP BY c.comp_producto, i.item_tipo, i.item_sucursal, i.item_numero
	HAVING COUNT(*) = (SELECT COUNT(*) FROM Composicion c2 WHERE c.comp_producto = c2.comp_producto)

	CREATE TABLE #insert_item(
	tempo_tipo CHAR(1),
	tempo_sucursal CHAR(4),
	tempo_numero CHAR(8),
	tempo_compuesto CHAR(8))

	CREATE TABLE #delete_item(
	tempo_tipo CHAR(1),
	tempo_sucursal CHAR(4),
	tempo_numero CHAR(8),
	tempo_componente CHAR(8))

	OPEN c_compuesto
	FETCH NEXT FROM c_compuesto INTO @producto, @tipo, @sucursal, @numero
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		--ingresamos datos a insertar en tabla temporal
		INSERT INTO #insert_item VALUES(@tipo, @sucursal, @numero, @producto)

		--ingresamos datos a eliminar en tabla temporal
		INSERT INTO #delete_item
		SELECT @tipo, @sucursal, @numero, comp_componente
		FROM Composicion WHERE comp_producto = @producto

		FETCH NEXT FROM c_compuesto INTO @producto, @tipo, @sucursal,@numero

	END
	CLOSE c_compuesto
	DEALLOCATE c_compuesto
	
	BEGIN TRANSACTION
	--delete item factura
	delete Item_Factura WHERE item_tipo+item_sucursal+item_numero+item_producto IN (SELECT tempo_tipo+tempo_sucursal+tempo_numero+tempo_componente 
																					FROM #delete_item)
	
	--insert item factura
	insert Item_Factura
	SELECT tempo_tipo, tempo_sucursal, tempo_numero, tempo_compuesto, 1
	FROM #insert_item if2
	INNER JOIN Producto p on if2.tempo_compuesto = p.prod_codigo

	COMMIT TRANSACTION

END 
GO

/*7. Hacer un procedimiento que dadas dos fechas complete la tabla Ventas. 
Debe insertar una línea por cada artículo con los movimientos de stock generados por las ventas entre esas fechas. 
La tabla se encuentra creada y vacía.

VENTAS

|	Código      | Detalle		|	Cant. Mov.		|	Precio de Venta	|	Renglón			|	Ganancia
---------------------------------------------------------------------------------------------------------------------------
|	Código del  | Detalle del	|	Cantidad de		|	Precio promedio	|	Nro. de línea	|	Precio de Venta
|	artículo	| artículo		|	movimientos de	|	de venta		|	de la tabla		|	– Cantidad * Costo Actual
|				|				|	ventas (Item	|					|					|
|				|				|	factura)		|					|					|

*/--STORE PROCEDURE + LLENADO


/*8. Realizar un procedimiento que complete la tabla Diferencias de precios, para los productos facturados que tengan composición 
y en los cuales el precio de facturación sea diferente al precio del cálculo de los precios unitarios por cantidad de sus componentes, 
se aclara que un producto que compone a otro, también puede estar compuesto por otros y así sucesivamente, la tabla se debe
crear y está formada por las siguientes columnas:

DIFERENCIAS

|	Código      | Detalle		|	Cantidad		|	Precio_generado	|	Precio-facurado
-------------------------------------------------------------------------------------------
|	Código del  | Detalle del	|	Cantidad de		|	Precio que se 	|	Precio del
|	artículo	| artículo		|	productos que	|	compone a 		|	producto		
|				|				|	conforman el 	|	través de sus 	|					
|				|				|	combo			|	componentes		|					

*/ -- IDEM 7

/*9. Crear el/los objetos de base de datos que ante alguna modificación de un ítem de
factura de un artículo con composición realice el movimiento de sus correspondientes componentes.*/-- TRIGGER

/*10. Crear el/los objetos de base de datos que ante el intento de borrar un artículo
verifique que no exista stock y si es así lo borre en caso contrario que emita un mensaje de error.*/-- Hecho en clase

CREATE TRIGGER tr_ejercicio_10
ON Producto
INSTEAD OF DELETE
AS
BEGIN
	IF EXISTS (SELECT 1 FROM STOCK s WHERE s.stoc_producto IN (SELECT d.prod_codigo FROM DELETED d)
				AND ISNULL(s.stoc_cantidad, 0) != 0)
		ROLLBACK;

	DELETE FROM STOCK WHERE stoc_producto IN (SELECT d.prod_codigo FROM DELETED d)

	DELETE FROM Producto WHERE prod_codigo IN (SELECT d.prod_codigo FROM DELETED d)
END
GO

/*11. Cree el/los objetos de base de datos necesarios para que dado un código de empleado se retorne 
la cantidad de empleados que este tiene a su cargo (directa o indirectamente). 
Solo contar aquellos empleados (directos o indirectos) que tengan un código mayor que su jefe directo.*/ -- STORE PROCEDURE

CREATE PROCEDURE pr_ejercicio_11 (@codigoEmpleado NUMERIC(6, 0), @cantEmpleados INT OUTPUT) AS
BEGIN

DECLARE @totalUltimoNivel INT
DECLARE @totalNivel INT
DECLARE @nivel INT

SET @cantEmpleados = 0
SET @nivel = 1

CREATE TABLE empleadosCantidades (
empl_codigo numeric(6, 0),
nivel INT)

INSERT INTO empleadosCantidades 
SELECT empl_codigo, @nivel FROM empleado WHERE empl_jefe = @codigoEmpleado

SELECT @totalUltimoNivel = COUNT(*) FROM empleadosCantidades
	
	WHILE @totalUltimoNivel > 0
		BEGIN 
			SELECT @totalNivel = COUNT(*) FROM empleadosCantidades WHERE empl_codigo > @codigoEmpleado AND nivel = @nivel
			SET @cantEmpleados = @cantEmpleados + @totalNivel
			
			INSERT INTO empleadosCantidades	
			SELECT empl_codigo, @nivel + 1 FROM Empleado WHERE empl_jefe IN (SELECT empl_codigo FROM empleadosCantidades WHERE nivel = @nivel)
			
			DELETE FROM empleadosCantidades WHERE nivel = @nivel
			
			SET @nivel = @nivel + 1

			SELECT @totalUltimoNivel = COUNT(*) FROM empleadosCantidades
		END

DROP TABLE empleadosCantidades
END

/*12. Cree el/los objetos de base de datos necesarios para que nunca un producto pueda ser compuesto por sí mismo. 
Se sabe que en la actualidad dicha regla se cumple y que la base de datos es accedida por n aplicaciones de diferentes tipos y tecnologías. 
No se conoce la cantidad de niveles de composición existentes.*/ --TRIGGER

/*13. Cree el/los objetos de base de datos necesarios para implantar la siguiente regla
“Ningún jefe puede tener un salario mayor al 20% de las suma de los salarios de sus empleados totales (directos + indirectos)”. 
Se sabe que en la actualidad dicha regla se cumple y que la base de datos es accedida por n aplicaciones de diferentes tipos y tecnologías.*/ --TRIGGER

/*14. Agregar el/los objetos necesarios para que si un cliente compra un producto compuesto  a un precio menor 
que la suma de los precios de sus componentes que imprima la fecha, que cliente, que productos y a qué precio se realizó la compra. 
No se deberá permitir que dicho precio sea menor a la mitad de la suma de los componentes.*/-- STORE PROCEDURE

/*15. Cree el/los objetos de base de datos necesarios para que el objeto principal reciba un producto como parametro y retorne el precio del mismo.
Se debe prever que el precio de los productos compuestos sera la sumatoria de los componentes del mismo multiplicado por sus respectivas cantidades. 
No se conocen los nivles de anidamiento posibles de los productos. 
Se asegura que nunca un producto esta compuesto por si mismo a ningun nivel. 
El objeto principal debe poder ser utilizado como filtro en el where de una sentencia select.*/

CREATE FUNCTION fx_ejercicio_15 (@producto char (8))
RETURNS decimal (12,2)
AS
BEGIN
	DECLARE @precio decimal (12,2)
	IF (@producto IN (SELECT comp_producto FROM Composicion))
		SET @precio = (select SUM(dbo.fx_ejercicio_15(comp_componente)*comp_cantidad) FROM Composicion WHERE @producto = comp_producto)
	ELSE 
	SET @precio = (SELECT prod_precio FROM producto where @producto = prod_codigo)

RETURN @precio
END
GO

/*16. Desarrolle el/los elementos de base de datos necesarios para que ante una venta automaticamante se descuenten del stock los articulos vendidos.
Se descontaran del deposito que mas producto posea y se supone que el stock se almacena tanto de productos simples como compuestos 
(si se acaba el stock de los compuestos no se arman combos).
En caso que no alcance el stock de un depósito se descontará del siguiente y así hasta agotar los depósitos posibles. 
En última instancia se dejará stock negativo en el último depósito que se descontó.*/

CREATE TRIGGER tr_ejercicio_16
ON Item_factura
AFTER INSERT 
AS 
BEGIN 

	DECLARE @cantidad DECIMAL(12, 2)
	DECLARE @producto CHAR(8)
	DECLARE @totalStock INT
	DECLARE @deposito CHAR(2)
	DECLARE @remanente INT
	DECLARE c_ejercicio_16 CURSOR FOR SELECT item_cantidad, item_producto FROM inserted 

	IF EXISTS (SELECT 1 FROM inserted i WHERE NOT EXISTS (SELECT 1 FROM STOCK WHERE stoc_producto = i.item_producto))
	ROLLBACK TRANSACTION

	OPEN c_ejercicio_16
	FETCH NEXT FROM c_ejercicio_16 INTO @cantidad, @producto

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM STOCK WHERE stoc_producto = @producto)
		ROLLBACK TRANSACTION

		SET @remanente = @cantidad
		
		SELECT TOP 1 @totalStock = ISNULL(stoc_cantidad, 0), @deposito = stoc_deposito 
		FROM stock WHERE stoc_producto = @producto
		ORDER BY ISNULL(stoc_cantidad, 0) DESC

		WHILE @remanente > 0
		BEGIN

			IF (@totalStock > 0 AND @totalStock > @remanente) OR (@totalStock <= 0)
			BEGIN	
				UPDATE stock SET stoc_cantidad = ISNULL(stoc_cantidad, 0) - @remanente
				WHERE stoc_deposito = @deposito AND stoc_producto = @producto
				SET @remanente = 0
			END
			
			ELSE 
				IF (@remanente > @totalStock) 	
				BEGIN
					UPDATE stock SET stoc_cantidad = 0
					WHERE stoc_deposito = @deposito AND stoc_producto = @producto
				
					SET @remanente = @remanente - @cantidad
				
					SELECT TOP 1 @totalStock = ISNULL(stoc_cantidad, 0), @deposito = stoc_deposito 
					FROM stock WHERE stoc_producto = @producto
					ORDER BY ISNULL(stoc_cantidad, 0) DESC
				END

		END

		FETCH NEXT FROM c_ejercicio_16 INTO @cantidad, @producto

	END
	CLOSE c_ejercicio_16
	DEALLOCATE c_ejercicio_16

END

/*17. Sabiendo que el punto de reposicion del stock es la menor cantidad de ese objeto que se debe almacenar en el deposito 
y que el stock maximo es la maxima cantidad de ese producto en ese deposito, cree el/los objetos de base de datos necesarios 
para que dicha regla de negocio se cumpla automaticamente.
No se conoce la forma de acceso a los datos ni el procedimiento por el cual se incrementa o descuenta stock*/--Hecho en clase

CREATE TRIGGER tr_ejercicio_17
ON STOCK
AFTER INSERT, UPDATE
AS
BEGIN
	IF EXISTS (SELECT 1 FROM STOCK s INNER JOIN inserted i on s.stoc_producto+s.stoc_deposito = i.stoc_producto+s.stoc_deposito 
			  WHERE s.stoc_cantidad IS NULL OR s.stoc_cantidad BETWEEN ISNULL(s.stoc_punto_reposicion, s.stoc_cantidad) 
																   AND ISNULL(s.stoc_stock_maximo, s.stoc_cantidad))
		ROLLBACK TRANSACTION
END
GO


/*18. Sabiendo que el limite de credito de un cliente es el monto maximo que se le puede facturar mensualmente, 
cree el/los objetos de base de datos necesarios para que dicha regla de negocio se cumpla automaticamente. 
No se conoce la forma de acceso a los datos ni el procedimiento por el cual se emiten las facturas*/

/*19. Cree el/los objetos de base de datos necesarios para que se cumpla la siguiente regla de negocio automáticamente 
“Ningún jefe puede tener menos de 5 años de antigüedad y tampoco puede tener más del 50% del personal a su cargo
(contando directos e indirectos) a excepción del gerente general”. 
Se sabe que en la actualidad la regla se cumple y existe un único gerente general.*/

/*20. Crear el/los objeto/s necesarios para mantener actualizadas las comisiones del vendedor.
El cálculo de la comisión está dado por el 5% de la venta total efectuada por ese vendedor en ese mes, 
más un 3% adicional en caso de que ese vendedor haya vendido por lo menos 50 productos distintos en el mes.*/

/*21. Desarrolle el/los elementos de base de datos necesarios para que se cumpla automaticamente 
la regla de que en una factura no puede contener productos de diferentes familias. 
En caso de que esto ocurra no debe grabarse esa factura y debe emitirse un error en pantalla.*/

/*22. Se requiere recategorizar los rubros de productos, de forma tal que nigun rubro tenga más de 20 productos asignados, 
si un rubro tiene más de 20 productos asignados se deberan distribuir en otros rubros que no tengan mas de 20 productos 
y si no entran se debra crear un nuevo rubro en la misma familia con la descirpción “RUBRO REASIGNADO”, 
cree el/los objetos de base de datos necesarios para que dicha regla de negocio quede implementada.*/

/*23. Desarrolle el/los elementos de base de datos necesarios para que ante una venta automaticamante 
se controle que en una misma factura no puedan venderse más de dos productos con composición. 
Si esto ocurre debera rechazarse la factura.*/

/*24. Se requiere recategorizar los encargados asignados a los depositos. 
Para ello cree el o los objetos de bases de datos necesarios que lo resueva, teniendo en cuenta que un deposito 
no puede tener como encargado un empleado que pertenezca a un departamento que no sea de la misma zona que el deposito, 
si esto ocurre a dicho deposito debera asignársele el empleado con menos depositos asignados que pertenezca a un departamento de esa zona.*/

/*25. Desarrolle el/los elementos de base de datos necesarios para que no se permita que la composición de los productos sea recursiva, 
o sea, que si el producto A compone al producto B, dicho producto B no pueda ser compuesto por el producto A, hoy la regla se cumple.*/

/*26. Desarrolle el/los elementos de base de datos necesarios para que se cumpla automaticamente 
la regla de que una factura no puede contener productos que sean componentes de otros productos. 
En caso de que esto ocurra no debe grabarse esa factura y debe emitirse un error en pantalla.*/

/*27. Se requiere reasignar los encargados de stock de los diferentes depósitos. 
Para ello se solicita que realice el o los objetos de base de datos necesarios 
para asignar a cada uno de los depósitos el encargado que le corresponda,
entendiendo que el encargado que le corresponde es cualquier empleado que no es jefe y que no es vendedor, 
o sea, que no está asignado a ningun cliente, se deberán ir asignando tratando de que un empleado solo tenga un deposito asignado, 
en caso de no poder se irán aumentando la cantidad de depósitos progresivamente para cada empleado.*/

/*28. Se requiere reasignar los vendedores a los clientes. 
Para ello se solicita que realice el o los objetos de base de datos necesarios para asignar a cada uno de los
clientes el vendedor que le corresponda, entendiendo que el vendedor que le corresponde es aquel que le vendió más facturas a ese cliente, 
si en particular un cliente no tiene facturas compradas se le deberá asignar el vendedor con más venta de la empresa, 
o sea, el que en monto haya vendido más.*/

CREATE PROCEDURE pr_ejercicio_28 AS
BEGIN


	DECLARE @vendedor NUMERIC(6, 0)

	SELECT TOP 1 @vendedor FROM Factura f
	WHERE fact_vendedor IS NOT NULL
	GROUP BY fact_vendedor								
	ORDER BY SUM(f.fact_total) DESC 
	
	BEGIN TRANSACTION

	UPDATE Cliente SET clie_vendedor = (SELECT TOP 1 fact_vendedor FROM Factura f
									WHERE f.fact_cliente = Cliente.clie_codigo
									GROUP BY fact_vendedor
									ORDER BY COUNT(*) DESC)
	WHERE EXISTS (SELECT 1 FROM Factura f WHERE f.fact_vendedor IS NOT NULL AND f.fact_cliente = Cliente.clie_codigo) 
		AND clie_vendedor != (SELECT TOP 1 fact_vendedor FROM Factura f
							WHERE f.fact_cliente = Cliente.clie_codigo
							GROUP BY fact_vendedor
							ORDER BY COUNT(*) DESC)
		AND clie_razon_social NOT LIKE 'CONSUMIDOR FINAL%' 

	UPDATE Cliente SET clie_vendedor = @vendedor	
	WHERE NOT EXISTS (SELECT 1 FROM Factura f WHERE f.fact_vendedor IS NOT NULL AND f.fact_cliente = Cliente.clie_codigo) 
		AND clie_vendedor != @vendedor
		AND clie_razon_social NOT LIKE 'CONSUMIDOR FINAL%' 

	COMMIT TRANSACTION
END

/*29. Desarrolle el/los elementos de base de datos necesarios para que se cumpla automaticamente 
la regla de que una factura no puede contener productos que sean componentes de diferentes productos. 
En caso de que esto ocurra no debe grabarse esa factura y debe emitirse un error en pantalla.*/

/*30. Agregar el/los objetos necesarios para crear una regla por la cual un cliente no pueda comprar más de 100 unidades en el mes de ningún producto,
si esto ocurre no se deberá ingresar la operación y se deberá emitir un mensaje “Se ha superado el límite máximo de compra de un producto”. 
Se sabe que esta regla se cumple y que las facturas no pueden ser modificadas.*/

/*31. Desarrolle el o los objetos de base de datos necesarios, para que un jefe no pueda tener más de 20 empleados a cargo, directa o indirectamente,
si esto ocurre debera asignarsele un jefe que cumpla esa condición, si no existe un jefe para asignarle 
se le deberá colocar como jefe al gerente general que es aquel que no tiene jefe.*/