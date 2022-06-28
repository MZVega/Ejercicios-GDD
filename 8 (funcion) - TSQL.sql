Create function FN_CALCULAR_SUMA_COMPONENTES (@producto char(8))
returns decimal(12,2)
as
	begin
		declare @costo decimal(12,2);
		declare @cantidad decimal(12,2);
		declare @componente char(8);
		
		if NOT EXISTS(SELECT * FROM Composicion WHERE comp_producto = @producto)
		begin
			set @costo = (select isnull(prod_precio,0) from Producto where prod_codigo=@producto)
			RETURN @costo
		end;
		
		set @costo = 0;
		
		declare cComp cursor for
		select comp_componente, comp_cantidad
		from Composicion 
		where comp_producto = @producto
		
		open cComp
		fetch next from cComp into @componente, @cantidad
		while @@FETCH_STATUS = 0
			begin
				set @costo = @costo + (dbo.FN_CALCULAR_SUMA_COMPONENTES(@componente) * @cantidad
				fetch next from cComp into @componente, @cantidad
			end
		close cComp;
		deallocate cComp;	
		return @costo;	
	end;