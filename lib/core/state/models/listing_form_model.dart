class ListingFormData {
  // Step 1: Type and Location
  String? transactionType; // 'sale' or 'rent'
  String? propertyType; // 'apartment', 'house', 'land', 'commercial'
  String? city;
  String? district;
  String? street;
  double? latitude;
  double? longitude;
  
  // Step 2: Basic Info
  double? price;
  double? area;
  int? rooms;
  int? floor;
  int? yearBuilt;
  String? condition;
  
  // Step 3: Details
  List<String> amenities = [];
  String? heating;
  String? description;
  
  // Step 4: Photos
  List<String> images = [];
  
  // Step 5: Contact
  String? contactName;
  String? contactPhone;
  String? contactEmail;
  String? preferredContactTime;
  
  // Step 6: Package
  String? package; // 'basic' or 'promoted'
  bool acceptedTerms = false;
  
  ListingFormData();
  
  bool isStep1Valid() {
    return transactionType != null && 
           propertyType != null && 
           city != null;
  }
  
  bool isStep2Valid() {
    return price != null && 
           area != null && 
           rooms != null;
  }
  
  bool isStep3Valid() {
    return description != null && 
           description!.length >= 50;
  }
  
  bool isStep4Valid() {
    return images.isNotEmpty;
  }
  
  bool isStep5Valid() {
    return contactName != null && 
           contactPhone != null && 
           contactEmail != null;
  }
  
  bool isStep6Valid() {
    return package != null && acceptedTerms;
  }
}
