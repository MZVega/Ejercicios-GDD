use gd2020

create function ej1 (@producto char(8), @deposito char(2))
returns char(60)
AS
BEGIN 
declare @cantidad numeric(12,2), @maximo decimal(12,2), @RETORNO CHAR(60)
select @cantidad = stoc_cantidad, @maximo = stoc_stock_maximo from STOCK
	where stoc_producto= @producto and stoc_deposito = @deposito
	 
if @cantidad > @maximo 
	SET @RETORNO = 'DEPOSITO COMPLETO'
ELSE 
	SET @RETORNO = 'OCUPACION DEL DEPOSITO '+@DEPOSITO+' '+ STR(@CANTIDAD/@MAXIMO*100,12,2)+'%'
RETURN @RETORNO	
END



DROP FUNCTION DBO.EJ1 

create function ej1 (@producto char(8), @deposito char(2))
RETURNS CHAR(60)

AS
BEGIN
RETURN (SELECT CASE WHEN STOC_CANTIDAD > STOC_STOCK_MAXIMO THEN 'DEPOSITO COMPLETO' 
	ELSE 'OCUPACION DEL DEPOSITO '+STOC_DEPOSITO+' '+ STR(STOC_CANTIDAD/stoc_stock_maximo*100,12,2)+'%'  END
	FROM STOCK
	where stoc_producto= @producto and stoc_deposito = @deposito)
END