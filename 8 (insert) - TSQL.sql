create table DIFERENCIAS
(
dife_producto char(8),
dife_detalle char(50),
dife_cantidad integer,
dife_precio_generado decimal(12,2),
dife_precio_facturado decimal(12,2)
)

create procedure SP_DIFERENCIAS()
as
begin
	insert into DIFERENCIAS
	(dife_producto, dife_detalle, dife_cantidad, dife_precio_generado, dife_precio_facturado)
	select prod_codigo, prod_detalle, COUNT(distinct comp_componente), dbo.FN_CALCULAR_SUMA_COMPONENTES(prod_codigo), item_precio
	from Producto join Item_Factura on (prod_codigo = item_producto) 
				  join Composicion on (prod_codigo=comp_producto)
	where item_precio <> dbo.FN_CALCULAR_SUMA_COMPONENTES(prod_codigo)
	group by prod_codigo, prod_detalle, item_precio
end