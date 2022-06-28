ALTER FUNCTION dbo.Ejercicio13Func (@Jefe numeric(6,0))
RETURNS decimal(12,2)

AS
BEGIN
       DECLARE @SueldoEmpl decimal(12,2)
       DECLARE @JefeAux numeric(6,0) = @Jefe
       DECLARE @CodEmplAux numeric(6,0)
       IF NOT EXISTS (SELECT * FROM EMPLEADO WHERE empl_jefe = @Jefe)
       BEGIN
              SET @SueldoEmpl = 0
              RETURN @SueldoEmpl
       END
       SET @SueldoEmpl = (SELECT SUM(dbo.Ejercicio13Func(empl_salario))
                                           FROM Empleado
                                           WHERE empl_jefe = @Jefe  --AND empl_codigo > @Jefe
                                           )
       RETURN @SueldoEmpl
END
GO

CREATE TRIGGER Ejercicio13 ON Empleado FOR INSERT, UPDATE
AS
BEGIN
       IF EXISTS(
              SELECT I.empl_codigo
              FROM inserted I
              WHERE I.empl_salario >  (dbo.Ejercicio13Func(I.empl_salario) * 0.2)
              )
              BEGIN
                     PRINT 'Un jefe no puede superar el 20% de la suma del sueldo total de sus empleados'
                     ROLLBACK
              END
       END
GO
