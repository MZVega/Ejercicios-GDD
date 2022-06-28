alter procedure SP_TSQL_3 AS
BEGIN
	declare @empleados_sin_jefe int
	set @empleados_sin_jefe = (SELECT COUNT(*) FROM EMPLEADO WHERE empl_jefe is null)
	if @empleados_sin_jefe > 1 
	begin
		update Empleado
		set empl_jefe = (SELECT TOP 1 EMPL_CODIGO 
						 FROM EMPLEADO 
						 WHERE empl_jefe is null 
						 ORDER BY empl_salario DESC, empl_ingreso ASC)
		WHERE empl_jefe is null and 
			  empl_codigo not in (SELECT TOP 1 EMPL_CODIGO 
								  FROM EMPLEADO 
								  where empl_jefe is null 
								  ORDER BY empl_salario DESC, empl_ingreso ASC)
	end

	Print 'CANTIDAD DE EMPLEADOS SIN JEFE : ' + str(@empleados_sin_jefe)


END

