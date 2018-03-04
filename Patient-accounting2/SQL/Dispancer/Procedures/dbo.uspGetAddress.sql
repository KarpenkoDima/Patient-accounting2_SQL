SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/* [Dispensary13102017].[dbo].[uspGetCustomerByAddress] */

/* DispensaryTemp.[dbo].[uspGetAddressByCustomerID] */

CREATE PROCEDURE [dbo].[uspGetAddress]
(
	@City NVARCHAR(100) NULL,
	@NameStreet NVARCHAR(100)	
)
AS
BEGIN
    	SET NOCOUNT ON;
    
		SET @City = ISNULL(@City, '%%');
    	IF @city IS NOT NULL AND @nameStreet IS NOT NULL
    	BEGIN    		
    
		  WITH CTE_GetCustomeIDByAddress(CustomerID)
    	AS(
    		SELECT customerID FROM [dbo].vGetAddress AS a
    		WHERE a.city like @City and a.NameStreet LIKE '%'+@NameStreet+'%'
    	)
		  SELECT vga.AddressID,
                 vga.AdminDivisionID,
                 vga.City,
                 vga.Country,
                 vga.CustomerID,
                 vga.ModifiedDate,
                 vga.NameStreet,
                 vga.NumberApartment,
                 vga.NumberHouse,
                 vga.Region,
                 vga.TypeStreetID FROM dbo.vGetAddress AS vga
				  INNER	JOIN CTE_GetCustomeIDByAddress AS cte_
				  ON  cte_.CustomerID = vga.CustomerID;	
    	END
    	END		

GO

GRANT EXECUTE ON [dbo].[uspGetAddress] TO [Sensitive_low] AS [dbo]
GO
