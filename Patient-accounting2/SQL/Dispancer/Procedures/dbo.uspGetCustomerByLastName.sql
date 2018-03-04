SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE uspGetCustomerByLastName
	-- Add the parameters for the stored procedure here
	@LastName NVARCHAR(100)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT [CustomerID]
      ,[MedCard]
      ,[CodeCustomer]
      ,[LastName]
      ,[FirstName]
      ,[MiddleName]
      ,[Birthday]
      ,[Arch]
      ,[APPPTPRID]
      ,[GenderID]
      ,[NotaBene] FROM vGetCustomers AS vgc
	WHERE vgc.LastName LIKE @LastName + '%'
END

GO

GRANT EXECUTE ON [dbo].[uspGetCustomerByLastName] TO [Sensitive_low] AS [dbo]
GO
