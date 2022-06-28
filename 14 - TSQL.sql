CREATE TRIGGER EJ14 ON ITEM_FACTURA INSTEAD OF INSERT 
AS 
BEGIN	
    DECLARE @PRODUCTO char(8),@PRECIO decimal(12,2), @CANTIDAD DECIMAL (12,2)
    DECLARE @FECHA smalldatetime, @CLIENTE char(6)
	DECLARE @TIPO CHAR, @SUCURSAL CHAR(4), @NUMERO CHAR(8)
    DECLARE cursorProd CURSOR for SELECT ITEM_TIPO, ITEM_SUCURSAL, ITEM_NUMERO, item_producto, item_precio, ITEM_CANTIDAD FROM inserted
	OPEN cursorProd
    FETCH NEXT FROM cursorProd INTO @tipo, @sucursal, @NUMERO, @PRODUCTO,@PRECIO, @CANTIDAD
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF(@PRECIO > dbo.precio_comp(@PRODUCTO) / 2)
			BEGIN 
				INSERT ITEM_FACTURA VALUES(@TIPO,@SUCURSAL,@NUMERO,@PRODUCTO,@CANTIDAD,@PRECIO)
				PRINT 'FECHA: ' + @FECHA + ' CLIENTE: ' + @CLIENTE + 'PRECIO: ' + @PRECIO + 'PRODUCTO: ' + @PRODUCTO
			END	 
        ELSE
			BEGIN
			DELETE FROM Item_Factura WHERE item_numero+item_sucursal+item_tipo = @NUMERO+@SUCURSAL+@TIPO
			DELETE FROM Factura WHERE fact_numero+fact_sucursal+fact_tipo = @NUMERO+@SUCURSAL+@TIPO
			RAISERROR('El precio no puede ser menor a la mitad.',1,1)
			END
		FETCH NEXT FROM cursorProd INTO @tipo, @sucursal, @numero, @PRODUCTO,@PRECIO, @CANTIDAD                                    
	END 
    CLOSE cursorProd
    DEALLOCATE cursorProd
END
