SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* [DispensaryMainTest].[dbo].[uspGetAddressByLastName] */

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE uspGetAddressByLastName
	-- Add the parameters for the stored procedure here
	@LastName NVARCHAR(100)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT [AddressID]
      ,[CustomerID]
      ,[Region]
      ,[Country]
      ,[City]
      ,[AdminDivisionID]
      ,[TypeStreetID]
      ,[NameStreet]
      ,[NumberHouse]
      ,[NumberApartment]
      ,[ModifiedDate] 
	FROM vGetAddress AS vga
	WHERE vga.CustomerID IN (SELECT vgc.CustomerID FROM vGetCustomers AS vgc WHERE lastname LIKE @LastName + '%')
	
END

GO

GRANT EXECUTE ON [dbo].[uspGetAddressByLastName] TO [Sensitive_low] AS [dbo]
GO
