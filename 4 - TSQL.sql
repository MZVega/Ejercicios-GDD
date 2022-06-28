create procedure SP_TSQL_4 AS
BEGIN
	declare @mejor_empleado int

	UPDATE Empleado
	SET empl_salario = empl_salario + ((select sum(fact_total) 
										from Factura 
										where fact_vendedor = empl_codigo) * empl_comision)

	set @mejor_empleado = (SELECT TOP 1 FACT_VENDEDOR 
						   FROM FACTURA
						   GROUP BY FACT_VENDEDOR
						   ORDER BY SUM(FACT_TOTAL) DESC)

	PRINT 'CODIGO DEL EMPLEADO QUE MAS VENDIO: ' + STR(@mejor_empleado)

END


