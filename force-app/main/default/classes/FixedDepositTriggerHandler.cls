public class FixedDepositTriggerHandler {
    
    public static void populateRelOfficer(List<FD_Details__c> fdList){
        // Branch_Relationship_Officer__c objectinde sorgulanacak Branch'lar belirlenir ve Set'in içine eklenir
        Set<String> branchNames = new Set<String>();
        for(FD_Details__c fd:fdList){
            if(String.isNotBlank(fd.Branch__c)){
                branchNames.add(fd.Branch__c);
            }
        }
		
        // branchNames Set'inin karşılıkları olan Relationship Officer bilgileri sorgulanır.
		List<Branch_Relationship_Officer__c> broList = new List<Branch_Relationship_Officer__c> ();
        if (!branchNames.isEmpty()){
            broList = [SELECT Name, Branch_Name__c, Relationship_Officer__c 
                   FROM Branch_Relationship_Officer__c 
                   WHERE Branch_Name__c IN :branchNames];  
            
        }
        // Branch ve Relationship Officer eşleştirmesi yapılarak Map içine eklenir
        Map<String, String> branchOfficers = new Map<String, String>();
        for(Branch_Relationship_Officer__c bro:broList){
            branchOfficers.put(bro.Branch_Name__c, bro.Relationship_Officer__c);
        }
        
        // Trigger'ı tetikleyen record'ların Relationship Officer fieldi assign edilir
        for(FD_Details__c fdToUpdate:fdList){
            if(String.isNotBlank(fdToUpdate.Branch__c)){
                fdToUpdate.Relationship_Officer__c = branchOfficers.get(fdToUpdate.Branch__c);
            }
        }
 
    }

    public static void shareWithRelOfficerAfterInsert(List<FD_Details__c> fdList){

        List<FD_Details__Share> fdShare = new List<FD_Details__Share>();

        for(FD_Details__c fd:fdList){
            // Relationship Officer'a yetki verilir
            if( String.isNotBlank(fd.Relationship_Officer__c) && fd.Relationship_Officer__c != fd.OwnerId){
                
                fdShare.add( createShareIns (fd.Id, fd.Relationship_Officer__c) );
                
            }
            // Sales Rep e yetki verilir
            if( String.isNotBlank(fd.Sales_Representative__c) && fd.Sales_Representative__c != fd.OwnerId){
                
                fdShare.add( createShareIns (fd.Id, fd.Sales_Representative__c) );
                
            }
        }
        // Döngü bittikten sonra share objecti insert edilir.
        Database.insert(fdShare, false);
    }

    public static void shareWithRelOfficerAfterUpdate(List<FD_Details__c> fdList, Map<Id, FD_Details__c> fdOldMap){
            // Yeni Relationship Officer'a yetki verilir.
        List<FD_Details__Share> fdShare = new List<FD_Details__Share>();

        for(FD_Details__c fd:fdList){

            if( String.isNotBlank(fd.Relationship_Officer__c) && 
            fd.Relationship_Officer__c != fd.OwnerId &&
            fd.Relationship_Officer__c != fdOldMap.get(fd.Id).Relationship_Officer__c){
                fdShare.add( createShareIns (fd.Id, fd.Relationship_Officer__c) );
                
            }
            // Eski Relationship Officer yetkisi kaldırılır
            if(fd.Relationship_Officer__c != fdOldMap.get(fd.Id).Relationship_Officer__c){
            List<FD_Details__Share> fdsOld = [SELECT Id, Rowcause, ParentId, UserOrGroupId 
                                             FROM FD_Details__Share
                                             WHERE UserOrGroupId = :fdOldMap.get(fd.Id).Relationship_Officer__c
                                             AND ParentId = :fd.Id
                                             AND Rowcause = 'Manual'];

                if(!fdsOld.isEmpty()){
                    Database.delete(fdsOld, false);
                }
            }
           


            // Yeni Sales Representative Yetki Verilir
            if( String.isNotBlank(fd.Sales_Representative__c) && 
            fd.Sales_Representative__c != fd.OwnerId &&
            fd.Sales_Representative__c != fdOldMap.get(fd.Id).Sales_Representative__c){
                fdShare.add( createShareIns (fd.Id, fd.Sales_Representative__c) );
                
            }
            // Eski Sales Representative yetkisi kaldırılır
            if(fd.Sales_Representative__c != fdOldMap.get(fd.Id).Sales_Representative__c) {
            List<FD_Details__Share> fdsSROld = [SELECT Id, Rowcause, ParentId, UserOrGroupId 
                                                FROM FD_Details__Share
                                                WHERE UserOrGroupId = :fdOldMap.get(fd.Id).Sales_Representative__c
                                                AND ParentId = :fd.Id
                                                AND Rowcause = 'Manual'];
                if(!fdsSROld.isEmpty()){
                    Database.delete(fdsSROld, false);
                }
            }

        }
        // Döngü bittikten sonra share objecti insert edilir.
        Database.insert(fdShare, false);
    }

    private static FD_Details__Share createShareIns (String recId, String userOrGroupId){
        FD_Details__Share fds = new FD_Details__Share();
        fds.ParentId = recId;
        fds.UserOrGroupId = userOrGroupId;
        fds.AccessLevel = 'Read';
        fds.RowCause = 'Manual';
        return fds;
    }
}