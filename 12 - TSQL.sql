/* 12 - Cree el/los objetos de base de datos necesarios para que nunca un producto
pueda ser compuesto por sí mismo. Se sabe que en la actualidad dicha regla se
cumple y que la base de datos es accedida por n aplicaciones de diferentes tipos
y tecnologías. No se conoce la cantidad de niveles de composición existentes.*/

CREATE TRIGGER ComposicionRecursiva ON Composicion INSTEAD OF INSERT, UPDATE
AS
BEGIN
--	IF (SELECT * FROM deleted) = 0 --si es un insert    ESTO NO LO PODE HACER ASI PORQUE EL SELECT * NO LO PODES IGUAL A 0
	IF ((SELECT COUNT(*) FROM DELETED) = 0)
		IF ((SELECT COUNT(*) FROM INSERTED WHERE dbo.Ejercicio12Func(comp_producto,comp_componente) = 1) > 0)  -- ACA ME FIJO SI ALGUNO NO CUMPLE LA REGLA
			PRINT 'No puede ingresarse un producto compuesto por si mismo'
		ELSE
			INSERT Composicion SELECT * FROM Inserted  WHERE dbo.Ejercicio12Func(comp_producto,comp_componente) = 0  -- ACA METO LOS QUE CUMPLEN LA REGLA
	ELSE
-- se crea otro cursor igual para deleted
		BEGIN
		DECLARE @productodel char(8)
		DECLARE @componentedel char(8)
		DECLARE @cantidaddel decimal (12,2)
		DECLARE cur_productosdel CURSOR FOR SELECT comp_cantidad, comp_producto, comp_componente FROM deleted
		DECLARE @producto char(8)
		DECLARE @componente char(8)
		DECLARE @cantidad decimal (12,2)
		DECLARE cur_productos CURSOR FOR SELECT comp_cantidad, comp_producto, comp_componente FROM inserted
		OPEN cur_productosdel
		OPEN cur_productos
		FETCH NEXT FROM cur_productosdel INTO @cantidaddel, @productodel, @componentedel
		FETCH NEXT FROM cur_productos INTO @cantidad, @producto, @componente
-- avanzan juntos
		WHILE @@FETCH_STATUS = 0
		BEGIN
-- me fijo si cumple la condicion 
			IF dbo.Ejercicio12Fun(@producto,@componente) = 1
				PRINT 'No puede moficiarse un producto compuesto por si mismo'
			ELSE
				BEGIN
-- hago el update borrando y cargando
-- borro el viejo
				DELETE Composicion WHERE comp_producto = @productodel and comp_componente = @componentedel
-- inserto el nuevo
				insert composicion values(@producto,@componente,@cantidad)
				END
-- avanzan los dos cursores juntos
			FETCH NEXT FROM cur_productosdel INTO @cantidaddel, @productodel, @componentedel
			FETCH NEXT FROM cur_productos INTO @cantidad, @producto, @componente
		END
		CLOSE cur_productosdel
		DEALLOCATE cur_productosdel
		CLOSE cur_productos
		DEALLOCATE cur_productos
	END
END