CREATE TRIGGER ej9 ON ITEM_FACTURA FOR UPDATE 
AS 
BEGIN
	DECLARE @COMPONENTE char(8),@CANTIDAD decimal(12,2)
	DECLARE cursorComponentes CURSOR FOR SELECT comp_componente, (I.item_cantidad - d.item_cantidad)*comp_cantidad FROM Composicion 
								JOIN inserted I on comp_producto = i.item_producto JOIN deleted d on comp_producto = d.item_producto
								WHERE i.item_cantidad != d.item_cantidad
	OPEN cursorComponentes
	FETCH NEXT FROM cursorComponentes 
	INTO @COMPONENTE,@CANTIDAD
	WHILE @@FETCH_STATUS = 0
	BEGIN
		UPDATE STOCK SET stoc_cantidad = stoc_cantidad - @CANTIDAD
		WHERE stoc_producto = @COMPONENTE AND STOC_DEPOSITO = (SELECT TOP 1 STOC_DEPOSITO FROM STOCK
									 WHERE STOC_PRODUCTO = @COMPONENTE ORDER BY STOC_CANTIDAD DESC)
		FETCH NEXT FROM cursorComponentes
		INTO @COMPONENTE,@CANTIDAD
	END
	CLOSE cursorComponentes
	DEALLOCATE cursorComponentes
END
