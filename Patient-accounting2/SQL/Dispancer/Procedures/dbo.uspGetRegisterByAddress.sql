SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[uspGetRegisterByAddress]
(
	@City NVARCHAR(100) NULL,
	@NameStreet NVARCHAR(100)	
)
AS
BEGIN
    	SET NOCOUNT ON;
    
    	IF @city IS NOT NULL AND @nameStreet IS NOT NULL
    	BEGIN
    	SET @City = ISNULL(@City, '%%');
    	SET @NameStreet = ISNULL(@NameStreet, '%%');
    
    	IF @City = N'' 
    	BEGIN
    		SET @City ='%%';
    	END 
    	IF @NameStreet = N'' 
    	BEGIN
    		SET @NameStreet ='%%';
    	END ;
		   WITH CTE_GetCustomeIDByAddress(CustomerID)
    	AS(
    		SELECT customerID FROM [dbo].[vGetAddress] AS a
    		WHERE a.City LIKE N'%%' AND a.NameStreet = @NameStreet
    	)
		  SELECT vgr.CustomerID,
                 vgr.Diagnosis,
                 vgr.FirstDeregister,
                 vgr.FirstRegister,
                 vgr.LandID,
                 vgr.ModifiedDate,
                 vgr.NotaBene,
                 vgr.RegisterID,
                 vgr.RegisterTypeID,
                 vgr.SecondDeRegister,
                 vgr.SecondRegister,
                 vgr.SecondRegisterTypeID,
                 vgr.WhyDeRegisterID,
                 vgr.WhySecondDeRegisterID  FROM dbo.vGetRegister AS vgr
				  INNER	JOIN CTE_GetCustomeIDByAddress AS cte_
				  ON  cte_.CustomerID = vgr.CustomerID;
	END 
		
END

GO
