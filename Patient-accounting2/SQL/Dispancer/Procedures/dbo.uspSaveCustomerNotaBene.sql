SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/* DispensaryMain.[dbo].[uspSaveCustomerNotaBene] */

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE uspSaveCustomerNotaBene
	-- Add the parameters for the stored procedure here
	@CustomerID INT = NULL,
	@NotaBene NTEXT = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    IF NOT EXISTS (
    	SELECT * FROM CustomerNotaBene
    	WHERE @CustomerID = CustomerID
    	) 
    	BEGIN
    		INSERT INTO CustomerNotaBene
    		(CustomerID, NotaBene) VALUES(@CustomerID, @NotaBene)
    	END
    ELSE
    	BEGIN
    		UPDATE [dbo].CustomerNotaBene
    		SET
    			-- APPPTPR -- this column value is auto-generated
    			NotaBene = @NotaBene
    		WHERE CustomerID  = @CustomerID
    	END
    
END

GO

GRANT EXECUTE ON [dbo].[uspSaveCustomerNotaBene] TO [Sensitive_medium] AS [dbo]
GO
