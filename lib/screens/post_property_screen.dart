import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import '../constants/dealer_terms.dart';
import '../models/property.dart';
import '../models/property_document.dart';
import '../models/property_media_item.dart';
import '../models/dealer_notification_model.dart';
import '../models/property_visualization_model.dart';
import '../services/property_state_service.dart';
import '../services/supabase_service.dart';
import '../services/supabase_storage_service.dart';
import '../services/smart_media_optimizer_service.dart';
import '../services/youtube_media_service.dart';
import '../services/dealer_lead_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../routes/app_routes.dart';
import 'location_picker_screen.dart';
import 'dealer_terms_screen.dart';
import 'user_profile_screen.dart';
import 'dual_auth_screen.dart';
import 'email_verification_screen.dart';
import 'main_shell.dart';
import 'property_details_screen.dart';

class PostPropertyScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const PostPropertyScreen({super.key, this.onNavigateTab});

  @override
  State<PostPropertyScreen> createState() => _PostPropertyScreenState();
}

class _PostPropertyScreenState extends State<PostPropertyScreen> {
  int _currentStep = 0;
  final int _totalSteps = 7;

  // Draft Property ID (persisted throughout form lifecycle)
  late final String _draftPropertyId;

  // Uploaded Documents & Image States
  PropertyDocument? _reraDoc;
  PropertyDocument? _floorPlanDoc;
  final List<PropertyDocument> _propertyImageDocs = [];

  bool _isUploadingRera = false;
  bool _isUploadingFloorPlan = false;
  bool _isUploadingPhotos = false;

  String? _uploadErrorRera;
  String? _uploadErrorFloorPlan;
  String? _uploadErrorPhotos;

  // User Type (Owner, Dealer, Builder)
  String _selectedUserType = 'Owner';

  // State Selection
  String _selectedState = 'Uttar Pradesh';
  final List<String> _stateOptions = const [
    'Uttar Pradesh',
    'Haryana',
    'Delhi NCR',
    'Maharashtra',
    'Karnataka',
    'Other',
  ];

  // Area Unit Selection
  String _selectedAreaUnit = 'sq ft';
  final List<String> _areaUnits = const ['sq ft', 'sq yd', 'sq m', 'acre'];

  // Bathrooms
  String _selectedBathrooms = '2';
  final List<String> _bathroomOptions = const ['1', '2', '3', '4', '5+'];

  // Mandatory Terms & Rights Checkboxes
  bool _confirmLegalRight = false;
  bool _agreeTermsAndPolicy = false;

  // Inline Validation Errors
  String? _titleError;
  String? _descError;
  String? _addressError;
  String? _sectorError;
  String? _pincodeError;
  String? _pinAutoDetectNotice;
  String? _priceError;
  String? _areaError;
  String? _bhkError;
  String? _bathroomError;
  String? _imageError;
  String? _termsError;
  String? _contactNameError;
  String? _contactPhoneError;
  String? _contactEmailError;

  // Submission & Idempotency States
  bool _isSubmitting = false;
  bool _isDraftSaving = false;
  String? _submittedRequestId;

  // Dealer Declarations & Terms Acceptance States
  bool _declarationAccuracy = false;
  bool _declarationAuthorization = false;
  bool _declarationContentRights = false;
  bool _declarationPricing = false;
  bool _declarationReview = false;
  bool _declarationTerms = false;
  bool _declarationDocuments = false;
  bool _declarationRera = false;
  bool _highlightDeclarationsError = false;

  bool get _allMandatoryDeclarationsAccepted =>
      _declarationAccuracy &&
      _declarationAuthorization &&
      _declarationContentRights &&
      _declarationPricing &&
      _declarationReview &&
      _declarationTerms &&
      _confirmLegalRight &&
      _agreeTermsAndPolicy;

  // Step 1: Basic Details
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _selectedCategory = 'Residential';

  // Step 2: Location Details
  String _selectedCity = 'Noida';
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _sectorController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  double _latitude = 28.4354;
  double _longitude = 77.4878;
  String _placeId = '';
  bool _hasSelectedMapLocation = false;

  // Step 3: Type & Price
  String _selectedType = 'Apartment';
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _sqftController = TextEditingController();
  final TextEditingController _carpetSqftController = TextEditingController();

  // Step 4: Configuration
  String _selectedBhk = '3 BHK';
  String _selectedFacing = 'East';
  String _selectedFurnishing = 'Semi-Furnished';
  String _selectedPossession = 'Ready to Move';

  // Step 5: Amenities
  final Set<String> _selectedAmenities = {'Club House', 'Gym', 'Swimming Pool', 'Security'};

  final List<String> _allAmenities = [
    'Club House',
    'Swimming Pool',
    'Gym',
    '24/7 Security',
    'Children Play Area',
    'Landscaped Garden',
    'Power Backup',
    'Lift',
    'Sports Facilities',
    'Parking',
    'EV Charging',
    'CCTV Surveillance',
    'Jogging Track',
    'Intercom'
  ];

  // Step 6: Legal & RERA & Media
  final TextEditingController _reraController = TextEditingController();
  final TextEditingController _youtubeUrlController = TextEditingController();

  // Optional Visualization URLs
  final TextEditingController _virtualTourController = TextEditingController();
  final TextEditingController _model3DController = TextEditingController();
  final TextEditingController _arModelController = TextEditingController();

  // Step 7: Contact Details
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  int _coverImageIndex = 0;
  String _uploadStageText = '';

  @override
  void initState() {
    super.initState();
    _draftPropertyId = 'PROP-DRAFT-${DateTime.now().millisecondsSinceEpoch}';

    // Pre-fill contact from UserSession
    _nameController = TextEditingController(
      text: UserSession.fullName.isNotEmpty ? UserSession.fullName : '',
    );
    _phoneController = TextEditingController(
      text: UserSession.mobileNumber.isNotEmpty ? UserSession.mobileNumber : '',
    );
    _emailController = TextEditingController(
      text: UserSession.email.isNotEmpty ? UserSession.email : '',
    );

    // Initial User Type default
    if (UserSession.isDealer) {
      _selectedUserType = 'Dealer';
    } else {
      _selectedUserType = 'Owner';
    }

    _titleController.addListener(() {
      if (_titleError != null) setState(() => _titleError = null);
    });
    _descController.addListener(() {
      if (_descError != null) setState(() => _descError = null);
    });
    _addressController.addListener(() {
      if (_addressError != null) setState(() => _addressError = null);
    });
    _sectorController.addListener(() {
      if (_sectorError != null) setState(() => _sectorError = null);
    });
    _pincodeController.addListener(() {
      if (_pincodeError != null) setState(() => _pincodeError = null);
    });
    _priceController.addListener(() {
      if (_priceError != null) setState(() => _priceError = null);
    });
    _sqftController.addListener(() {
      if (_areaError != null) setState(() => _areaError = null);
    });
    _phoneController.addListener(() {
      if (_contactPhoneError != null) setState(() => _contactPhoneError = null);
    });
    _emailController.addListener(() {
      if (_contactEmailError != null) setState(() => _contactEmailError = null);
    });

    debugPrint('[POST_PROPERTY] Initialized Draft Property ID: $_draftPropertyId');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _sectorController.dispose();
    _pincodeController.dispose();
    _priceController.dispose();
    _sqftController.dispose();
    _carpetSqftController.dispose();
    _reraController.dispose();
    _youtubeUrlController.dispose();
    _virtualTourController.dispose();
    _model3DController.dispose();
    _arModelController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String get _currentUserId {
    if (UserSession.isLoggedIn && UserSession.mobileNumber.isNotEmpty) {
      return 'usr_${UserSession.mobileNumber}';
    }
    final user = SupabaseService.instance.auth.currentUser;
    if (user != null && user.id.isNotEmpty) return user.id;
    return 'dealer_${_phoneController.text.replaceAll(RegExp(r'[^0-9]'), '')}';
  }

  // ===========================================================================
  // REAL FILE PICKER & SUPABASE STORAGE UPLOAD HANDLERS
  // ===========================================================================

  /// Pick and upload RERA Registration Certificate (PDF, JPG, PNG)
  Future<void> _pickAndUploadRera() async {
    debugPrint('[FILE_PICKER] picker opened for RERA Registration Certificate');

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('[FILE_PICKER] User cancelled picker');
        return;
      }

      final file = result.files.single;
      final fileName = file.name;
      final fileSize = file.size;
      final mimeType = SupabaseStorageService.resolveMimeType(fileName);

      debugPrint('[FILE_PICKER] file selected: $fileName');
      debugPrint('[FILE_PICKER] size: $fileSize bytes');
      debugPrint('[FILE_PICKER] mime type: $mimeType');

      // Validation 1: Size check (Max 10 MB = 10 * 1024 * 1024 bytes)
      if (fileSize > 10 * 1024 * 1024) {
        _showErrorSnackBar('File is too large. Maximum allowed size is 10 MB.');
        return;
      }

      // Validation 2: MIME / Extension check
      final ext = fileName.split('.').last.toLowerCase();
      if (!['pdf', 'jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
        _showErrorSnackBar('Unsupported file type. Please select PDF, JPG, JPEG or PNG.');
        return;
      }

      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        _showErrorSnackBar('Unable to read file data from browser.');
        return;
      }

      setState(() {
        _isUploadingRera = true;
        _uploadErrorRera = null;
      });

      final storagePath = '$_currentUserId/$_draftPropertyId/rera/$fileName';
      final uploadRes = await SupabaseStorageService.instance.uploadBinary(
        bucket: SupabaseStorageService.documentsBucket,
        path: storagePath,
        bytes: bytes,
        contentType: mimeType,
        userId: _currentUserId,
        propertyId: _draftPropertyId,
        documentType: 'RERA Registration Certificate',
        fileName: fileName,
      );

      if (uploadRes.isSuccess) {
        setState(() {
          _reraDoc = PropertyDocument(
            id: 'DOC-RERA-${DateTime.now().millisecondsSinceEpoch}',
            fileName: fileName,
            fileSizeBytes: fileSize,
            mimeType: mimeType,
            documentType: 'rera',
            storagePath: storagePath,
            fileUrl: uploadRes.fileUrl ?? '',
            uploadedAt: DateTime.now(),
            bytes: bytes,
          );
          _isUploadingRera = false;
        });
        _showSuccessSnackBar('✓ RERA Certificate ($fileName) uploaded successfully.');
      } else {
        setState(() {
          _isUploadingRera = false;
          _uploadErrorRera = uploadRes.errorMessage ?? 'Upload failed';
        });
        _showErrorSnackBar('RERA Upload Failed: ${_uploadErrorRera!}');
      }
    } catch (e) {
      debugPrint('[FILE_PICKER_ERROR] $e');
      setState(() {
        _isUploadingRera = false;
        _uploadErrorRera = e.toString();
      });
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  /// Pick and upload Master Floor Plan (PDF, JPG, PNG)
  Future<void> _pickAndUploadFloorPlan() async {
    debugPrint('[FILE_PICKER] picker opened for Master Floor Plan');

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('[FILE_PICKER] User cancelled picker');
        return;
      }

      final file = result.files.single;
      final fileName = file.name;
      final fileSize = file.size;
      final mimeType = SupabaseStorageService.resolveMimeType(fileName);

      debugPrint('[FILE_PICKER] file selected: $fileName');
      debugPrint('[FILE_PICKER] size: $fileSize bytes');
      debugPrint('[FILE_PICKER] mime type: $mimeType');

      // Validation: Size check
      if (fileSize > 10 * 1024 * 1024) {
        _showErrorSnackBar('File is too large. Maximum allowed size is 10 MB.');
        return;
      }

      // Validation: Format check
      final ext = fileName.split('.').last.toLowerCase();
      if (!['pdf', 'jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
        _showErrorSnackBar('Unsupported file type. Please select PDF, JPG, JPEG or PNG.');
        return;
      }

      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        _showErrorSnackBar('Unable to read file data from browser.');
        return;
      }

      setState(() {
        _isUploadingFloorPlan = true;
        _uploadErrorFloorPlan = null;
      });

      final storagePath = '$_currentUserId/$_draftPropertyId/floor-plan/$fileName';
      final uploadRes = await SupabaseStorageService.instance.uploadBinary(
        bucket: SupabaseStorageService.documentsBucket,
        path: storagePath,
        bytes: bytes,
        contentType: mimeType,
        userId: _currentUserId,
        propertyId: _draftPropertyId,
        documentType: 'Master Floor Plan',
        fileName: fileName,
      );

      if (uploadRes.isSuccess) {
        setState(() {
          _floorPlanDoc = PropertyDocument(
            id: 'DOC-FLOOR-${DateTime.now().millisecondsSinceEpoch}',
            fileName: fileName,
            fileSizeBytes: fileSize,
            mimeType: mimeType,
            documentType: 'floor_plan',
            storagePath: storagePath,
            fileUrl: uploadRes.fileUrl ?? '',
            uploadedAt: DateTime.now(),
            bytes: bytes,
          );
          _isUploadingFloorPlan = false;
        });
        _showSuccessSnackBar('✓ Master Floor Plan ($fileName) uploaded successfully.');
      } else {
        setState(() {
          _isUploadingFloorPlan = false;
          _uploadErrorFloorPlan = uploadRes.errorMessage ?? 'Upload failed';
        });
        _showErrorSnackBar('Floor Plan Upload Failed: ${_uploadErrorFloorPlan!}');
      }
    } catch (e) {
      debugPrint('[FILE_PICKER_ERROR] $e');
      setState(() {
        _isUploadingFloorPlan = false;
        _uploadErrorFloorPlan = e.toString();
      });
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  /// Pick and upload Multiple Property Photos
  Future<void> _pickAndUploadPhotos() async {
    if (_propertyImageDocs.length >= SmartMediaOptimizerService.maxImagesPerProperty) {
      _showErrorSnackBar('Maximum ${SmartMediaOptimizerService.maxImagesPerProperty} photos allowed per listing.');
      return;
    }

    debugPrint('[FILE_PICKER] picker opened for Property Photos');

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        allowMultiple: true,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('[FILE_PICKER] User cancelled photo picker');
        return;
      }

      setState(() {
        _isUploadingPhotos = true;
        _uploadStageText = 'Preparing image...';
      });

      int uploadSuccessCount = 0;
      double totalSavingsAcc = 0;

      for (int i = 0; i < result.files.length; i++) {
        final file = result.files[i];
        final fileName = file.name;
        final fileSize = file.size;

        if (fileSize > 15 * 1024 * 1024) {
          _showErrorSnackBar('$fileName exceeds the 15 MB file size limit.');
          continue;
        }

        if (_propertyImageDocs.length >= SmartMediaOptimizerService.maxImagesPerProperty) {
          _showErrorSnackBar('Upload limit reached (Max ${SmartMediaOptimizerService.maxImagesPerProperty} photos).');
          break;
        }

        debugPrint('[SMART_MEDIA_PICKER] photo selected: $fileName ($fileSize bytes)');

        final bytes = file.bytes;
        if (bytes == null || bytes.isEmpty) continue;

        setState(() {
          _uploadStageText = 'Optimizing & stripping EXIF (${i + 1}/${result.files.length})...';
        });

        // Perform smart client-side optimization, duplicate check & multi-tier compression
        final uploadRes = await SmartMediaOptimizerService.instance.uploadOptimizedPropertyImage(
          propertyId: _draftPropertyId,
          userId: _currentUserId,
          rawBytes: bytes,
          originalFileName: fileName,
          userRole: UserSession.roleTierNotifier.value,
          displayOrder: _propertyImageDocs.length + 1,
          isCover: _propertyImageDocs.isEmpty,
        );

        if (uploadRes.isSuccess) {
          uploadSuccessCount++;
          totalSavingsAcc += uploadRes.savingsPercent;
          setState(() {
            _imageError = null;
            _uploadErrorPhotos = null;
            _propertyImageDocs.add(
              PropertyDocument(
                id: uploadRes.imageId ?? 'IMG-${DateTime.now().millisecondsSinceEpoch}-${_propertyImageDocs.length}',
                fileName: fileName,
                fileSizeBytes: uploadRes.optimizedSizeBytes,
                mimeType: 'image/jpeg',
                documentType: 'photo',
                storagePath: uploadRes.storagePath ?? '',
                fileUrl: uploadRes.publicUrl ?? '',
                uploadedAt: DateTime.now(),
                bytes: bytes,
              ),
            );
          });
        } else if (uploadRes.isDuplicate) {
          _showErrorSnackBar('Same image already exists for this property ($fileName).');
        } else {
          setState(() {
            _uploadErrorPhotos = uploadRes.errorMessage ?? 'Upload failed';
          });
          _showErrorSnackBar(uploadRes.errorMessage ?? 'Failed to optimize and upload $fileName');
        }
      }

      setState(() {
        _isUploadingPhotos = false;
        _uploadStageText = '';
      });

      if (uploadSuccessCount > 0) {
        final avgSavings = (totalSavingsAcc / uploadSuccessCount).toStringAsFixed(0);
        _showSuccessSnackBar('✓ $uploadSuccessCount photo(s) optimized & uploaded ($avgSavings% storage saved).');
      }
    } catch (e) {
      debugPrint('[SMART_MEDIA_ERROR] $e');
      setState(() {
        _isUploadingPhotos = false;
        _uploadStageText = '';
      });
      _showErrorSnackBar('Error optimizing and uploading photos: $e');
    }
  }

  void _setCoverImage(int index) {
    if (index >= 0 && index < _propertyImageDocs.length) {
      setState(() {
        _coverImageIndex = index;
      });
      _showSuccessSnackBar('Cover image set to photo #${index + 1}');
    }
  }

  void _movePhotoLeft(int index) {
    if (index > 0 && index < _propertyImageDocs.length) {
      setState(() {
        final item = _propertyImageDocs.removeAt(index);
        _propertyImageDocs.insert(index - 1, item);
        if (_coverImageIndex == index) {
          _coverImageIndex = index - 1;
        } else if (_coverImageIndex == index - 1) {
          _coverImageIndex = index;
        }
      });
    }
  }

  void _movePhotoRight(int index) {
    if (index >= 0 && index < _propertyImageDocs.length - 1) {
      setState(() {
        final item = _propertyImageDocs.removeAt(index);
        _propertyImageDocs.insert(index + 1, item);
        if (_coverImageIndex == index) {
          _coverImageIndex = index + 1;
        } else if (_coverImageIndex == index + 1) {
          _coverImageIndex = index;
        }
      });
    }
  }

  void _removeReraDoc() async {
    if (_reraDoc != null) {
      await SupabaseStorageService.instance.deleteFile(
        bucket: SupabaseStorageService.documentsBucket,
        path: _reraDoc!.storagePath,
      );
      setState(() {
        _reraDoc = null;
        _uploadErrorRera = null;
      });
      _showSuccessSnackBar('RERA Certificate removed.');
    }
  }

  void _removeFloorPlanDoc() async {
    if (_floorPlanDoc != null) {
      await SupabaseStorageService.instance.deleteFile(
        bucket: SupabaseStorageService.documentsBucket,
        path: _floorPlanDoc!.storagePath,
      );
      setState(() {
        _floorPlanDoc = null;
        _uploadErrorFloorPlan = null;
      });
      _showSuccessSnackBar('Master Floor Plan removed.');
    }
  }

  void _removePhotoDoc(int index) async {
    if (index >= 0 && index < _propertyImageDocs.length) {
      final doc = _propertyImageDocs[index];
      await SupabaseStorageService.instance.deleteFile(
        bucket: SupabaseStorageService.imagesBucket,
        path: doc.storagePath,
      );
      setState(() {
        _propertyImageDocs.removeAt(index);
      });
      _showSuccessSnackBar('Photo removed.');
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.emeraldSuccess,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.coralDanger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ===========================================================================
  // FORM NAVIGATION & STEP VALIDATION
  // ===========================================================================

  bool _validateCurrentStep() {
    setState(() {
      _titleError = null;
      _descError = null;
      _sectorError = null;
      _addressError = null;
      _pincodeError = null;
      _priceError = null;
      _areaError = null;
      _bhkError = null;
      _bathroomError = null;
      _imageError = null;
      _termsError = null;
      _contactNameError = null;
      _contactPhoneError = null;
      _contactEmailError = null;
    });

    if (_currentStep == 0) {
      final tErr = FormValidators.validatePropertyTitle(_titleController.text);
      final dErr = FormValidators.validatePropertyDescription(_descController.text);
      if (tErr != null || dErr != null) {
        setState(() {
          _titleError = tErr;
          _descError = dErr;
        });
        return false;
      }
      return true;
    }

    if (_currentStep == 1) {
      final aErr = FormValidators.validateAddress(_addressController.text);
      final sErr = _sectorController.text.trim().isEmpty ? 'Sector or locality is required' : null;
      final pErr = FormValidators.validatePinCode(_pincodeController.text);
      if (aErr != null || sErr != null || pErr != null) {
        setState(() {
          _addressError = aErr;
          _sectorError = sErr;
          _pincodeError = pErr;
        });
        return false;
      }
      return true;
    }

    if (_currentStep == 2) {
      final prErr = FormValidators.validatePriceCr(_priceController.text);
      final arErr = FormValidators.validateArea(_sqftController.text, unit: _selectedAreaUnit);
      if (prErr != null || arErr != null) {
        setState(() {
          _priceError = prErr;
          _areaError = arErr;
        });
        return false;
      }
      return true;
    }

    if (_currentStep == 3) {
      if (FormValidators.isBhkRequired(_selectedType) && _selectedBhk.trim().isEmpty) {
        setState(() {
          _bhkError = 'BHK configuration is required for residential properties';
        });
        return false;
      }
      final bErr = FormValidators.validateBathroom(_selectedBathrooms);
      if (bErr != null) {
        setState(() {
          _bathroomError = bErr;
        });
        return false;
      }
      return true;
    }

    if (_currentStep == 4) {
      return true;
    }

    if (_currentStep == 5) {
      if (_propertyImageDocs.isEmpty) {
        setState(() {
          _imageError = 'At least 1 property photo is required before submitting.';
        });
        _showErrorSnackBar('Please upload at least 1 property photo.');
        return false;
      }
      return true;
    }

    if (_currentStep == 6) {
      final nErr = FormValidators.validateFullName(_nameController.text);
      final phErr = FormValidators.validateIndianPhone(_phoneController.text);
      final emErr = FormValidators.validateEmail(_emailController.text);
      if (nErr != null || phErr != null || emErr != null) {
        setState(() {
          _contactNameError = nErr;
          _contactPhoneError = phErr;
          _contactEmailError = emErr;
        });
        return false;
      }

      if (!_confirmLegalRight || !_agreeTermsAndPolicy) {
        setState(() {
          _termsError = 'Please accept both legal authorization and listing policy.';
        });
        _showErrorSnackBar('Please accept the Property Listing Policy.');
        return false;
      }
      return true;
    }

    return true;
  }

  void _onNext() {
    if (!_validateCurrentStep()) return;

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _submitProperty();
    }
  }

  Future<void> _saveDraft() async {
    if (_isDraftSaving || _isSubmitting) return;

    if (!UserSession.isLoggedIn) {
      _showErrorSnackBar('Please sign in to save a draft.');
      return;
    }

    setState(() => _isDraftSaving = true);

    try {
      final title = _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : 'Draft Property Listing';
      final priceCr = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final sqft = int.tryParse(_sqftController.text.trim()) ?? 0;
      final sector = _sectorController.text.trim().isNotEmpty ? _sectorController.text.trim() : 'Sector 150';
      final address = _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : '$sector, $_selectedCity';

      final draftProperty = Property(
        id: _draftPropertyId,
        title: title,
        sector: sector,
        city: _selectedCity,
        locality: sector,
        address: address,
        postalCode: _pincodeController.text.trim(),
        placeId: _placeId,
        latitude: _latitude,
        longitude: _longitude,
        category: _selectedCategory,
        propertyType: _selectedType,
        askingPriceCr: priceCr,
        fairValueCr: priceCr > 0 ? (priceCr * 1.05) : 1.0,
        priceRangeDisplay: priceCr > 0 ? '₹ $priceCr Cr' : '₹ Price on Request',
        pricePerSqft: (priceCr > 0 && sqft > 0) ? (priceCr * 10000000 / sqft).roundToDouble() : 6500,
        score10x: 9.0,
        rentalYieldPercent: 4.8,
        sqft: sqft,
        carpetAreaSqft: int.tryParse(_carpetSqftController.text.trim()) ?? 0,
        bhk: _selectedBhk,
        facing: _selectedFacing,
        furnishing: _selectedFurnishing,
        possessionStatus: _selectedPossession,
        description: _descController.text.trim(),
        amenities: _selectedAmenities.toList(),
        imageUrl: _propertyImageDocs.isNotEmpty ? _propertyImageDocs.first.fileUrl : '',
        galleryImages: _propertyImageDocs.map((d) => d.fileUrl).toList(),
        status: 'draft',
        isVerified: false,
        dealerName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : UserSession.fullName,
        dealerPhone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : UserSession.mobileNumber,
        dealerEmail: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : UserSession.email,
        declarations: {
          'user_type': _selectedUserType,
          'owner_id': _currentUserId,
          'is_draft': true,
        },
      );

      PropertyStateService.instance.addDealerPropertySubmission(draftProperty);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Draft saved successfully. Drafts are not publicly visible.'),
            backgroundColor: AppTheme.emeraldSuccess,
          ),
        );
      }
    } catch (e) {
      debugPrint('[POST_PROPERTY] Error saving draft: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to save draft: $e');
      }
    } finally {
      if (mounted) setState(() => _isDraftSaving = false);
    }
  }

  void _submitProperty() async {
    // Duplicate submission guard
    if (_isSubmitting) return;

    if (!UserSession.isLoggedIn) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const DualAuthScreen(redirectRoute: AppRoutes.listProperty),
        ),
      );
      return;
    }

    if (!UserSession.isEmailVerified) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const EmailVerificationGateScreen(redirectRoute: AppRoutes.listProperty),
        ),
      );
      return;
    }

    // Step validations
    final titleErr = FormValidators.validatePropertyTitle(_titleController.text);
    if (titleErr != null) {
      setState(() {
        _currentStep = 0;
        _titleError = titleErr;
      });
      _showErrorSnackBar(titleErr);
      return;
    }

    final descErr = FormValidators.validatePropertyDescription(_descController.text);
    if (descErr != null) {
      setState(() {
        _currentStep = 0;
        _descError = descErr;
      });
      _showErrorSnackBar(descErr);
      return;
    }

    final addrErr = FormValidators.validateAddress(_addressController.text);
    if (addrErr != null) {
      setState(() {
        _currentStep = 1;
        _addressError = addrErr;
      });
      _showErrorSnackBar(addrErr);
      return;
    }

    final pinErr = FormValidators.validatePinCode(_pincodeController.text);
    if (pinErr != null) {
      setState(() {
        _currentStep = 1;
        _pincodeError = pinErr;
      });
      _showErrorSnackBar(pinErr);
      return;
    }

    final priceErr = FormValidators.validatePriceCr(_priceController.text);
    if (priceErr != null) {
      setState(() {
        _currentStep = 2;
        _priceError = priceErr;
      });
      _showErrorSnackBar(priceErr);
      return;
    }

    final areaErr = FormValidators.validateArea(_sqftController.text, unit: _selectedAreaUnit);
    if (areaErr != null) {
      setState(() {
        _currentStep = 2;
        _areaError = areaErr;
      });
      _showErrorSnackBar(areaErr);
      return;
    }

    if (_propertyImageDocs.isEmpty) {
      setState(() {
        _currentStep = 5;
        _imageError = 'At least 1 property photo is required before submitting.';
      });
      _showErrorSnackBar('Please upload at least 1 property photo.');
      return;
    }

    if (!_confirmLegalRight || !_agreeTermsAndPolicy) {
      setState(() {
        _currentStep = 6;
        _termsError = 'Please accept both legal authorization and listing policy.';
      });
      _showErrorSnackBar('Please accept the Property Listing Policy.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submittedRequestId = 'REQ-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(99999)}';
    });

    final title = _titleController.text.trim();
    final priceCr = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final sqft = int.tryParse(_sqftController.text.trim()) ?? 0;
    final carpetSqft = int.tryParse(_carpetSqftController.text.trim()) ?? (sqft > 0 ? (sqft * 0.85).round() : 0);
    final sector = _sectorController.text.trim().isNotEmpty ? _sectorController.text.trim() : 'Sector 150';
    final address = _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : '$sector, $_selectedCity';
    final propId = 'PROP-DLR-${DateTime.now().millisecondsSinceEpoch}';

    final dealerName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : (UserSession.fullName.isNotEmpty ? UserSession.fullName : 'Verified User');
    final dealerPhone = _phoneController.text.trim().isNotEmpty
        ? _phoneController.text.trim()
        : (UserSession.mobileNumber.isNotEmpty ? UserSession.mobileNumber : '+91 98765 43210');
    final dealerEmail = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : (UserSession.email.isNotEmpty ? UserSession.email : 'user@propzen.ai');
    final dealerId = 'USER-${dealerPhone.replaceAll(RegExp(r'[^0-9]'), '')}';
    final nowStr = DateTime.now().toIso8601String();

    final galleryList = _propertyImageDocs.map((d) => d.fileUrl).toList();
    final primaryImageUrl = _propertyImageDocs.isNotEmpty
        ? (_coverImageIndex < _propertyImageDocs.length
            ? _propertyImageDocs[_coverImageIndex].fileUrl
            : _propertyImageDocs.first.fileUrl)
        : '';

    final ytVal = YouTubeMediaService.validateAndExtract(_youtubeUrlController.text.trim());

    // Construct Property Model with status = 'pending' (PENDING_VERIFICATION)
    final newProperty = Property(
      id: propId,
      title: title,
      sector: sector,
      city: _selectedCity,
      locality: sector,
      address: address,
      postalCode: _pincodeController.text.trim(),
      placeId: _placeId.isNotEmpty ? _placeId : 'prop_loc_${DateTime.now().millisecondsSinceEpoch}',
      latitude: _latitude,
      longitude: _longitude,
      category: _selectedCategory,
      propertyType: _selectedType,
      askingPriceCr: priceCr,
      fairValueCr: priceCr > 0 ? (priceCr * 1.05) : 1.0,
      priceRangeDisplay: priceCr > 0 ? '₹ $priceCr Cr' : '₹ Price on Request',
      pricePerSqft: (priceCr > 0 && sqft > 0) ? (priceCr * 10000000 / sqft).roundToDouble() : 6500,
      score10x: 9.1,
      rentalYieldPercent: 4.8,
      sqft: sqft > 0 ? sqft : 1200,
      carpetAreaSqft: carpetSqft,
      bhk: FormValidators.isBhkRequired(_selectedType) ? _selectedBhk : 'N/A',
      imageUrl: primaryImageUrl,
      galleryImages: galleryList,
      youtubeVideoId: ytVal.isValid ? ytVal.videoId : null,
      youtubeUrl: ytVal.isValid ? ytVal.watchUrl : null,
      optimizedThumbnailUrl: _propertyImageDocs.isNotEmpty ? _propertyImageDocs.first.fileUrl : null,
      optimizedMediumUrl: _propertyImageDocs.isNotEmpty ? _propertyImageDocs.first.fileUrl : null,
      reraDocumentUrl: _reraDoc?.fileUrl,
      floorPlanUrl: _floorPlanDoc?.fileUrl,
      dealerId: dealerId,
      dealerName: dealerName,
      dealerPhone: dealerPhone,
      dealerEmail: dealerEmail,
      contactName: dealerName,
      contactPhone: dealerPhone,
      contactEmail: dealerEmail,
      possessionDate: _selectedPossession,
      status: 'pending', // Strictly PENDING_VERIFICATION until Admin Approval
      isVerified: false,
      adminNote: null,
      termsAccepted: true,
      termsVersion: DealerTermsConfig.currentVersion,
      termsAcceptedAt: nowStr,
      termsAcceptedBy: dealerName,
      declarationAccuracyAccepted: _declarationAccuracy,
      declarationAuthorizationAccepted: _declarationAuthorization,
      declarationContentRightsAccepted: _declarationContentRights,
      declarationPricingAccepted: _declarationPricing,
      declarationReviewAccepted: _declarationReview,
      declarationTermsAccepted: _declarationTerms,
      declarations: {
        'legal_right_confirmed': _confirmLegalRight,
        'terms_policy_agreed': _agreeTermsAndPolicy,
        'user_type': _selectedUserType,
        'request_id': _submittedRequestId,
        'accuracy': _declarationAccuracy,
        'authorization': _declarationAuthorization,
        'content_rights': _declarationContentRights,
        'pricing': _declarationPricing,
        'review_consent': _declarationReview,
        'terms_agreement': _declarationTerms,
        'documents_authorized': _declarationDocuments,
        'rera_declared': _declarationRera,
        'rera_doc_uploaded': _reraDoc != null,
        'floor_plan_uploaded': _floorPlanDoc != null,
        'photos_count': _propertyImageDocs.length,
      },
      reraStatus: _reraController.text.trim().isNotEmpty ? 'Approved' : 'Pending',
      possessionStatus: _selectedPossession,
      furnishingStatus: _selectedFurnishing,
      facing: _selectedFacing,
      furnishing: _selectedFurnishing,
      availability: _selectedPossession,
      amenities: _selectedAmenities.toList(),
      description: _descController.text.trim(),
      reraId: _reraController.text.trim().isNotEmpty ? _reraController.text.trim() : 'UPRERAPRJ999888',
      virtualTour: _virtualTourController.text.trim().isNotEmpty
          ? VirtualTourData(
              title: '$title 360° Virtual Tour',
              panoramaUrl: _virtualTourController.text.trim(),
              provider: _virtualTourController.text.trim().contains('matterport') ? 'matterport' : 'kuula',
              isAvailable: true,
              rooms: [
                VirtualTourRoom(
                  id: 'main-view',
                  name: 'Main Panorama View',
                  imageUrl: primaryImageUrl,
                  area: '$sqft sq.ft.',
                  panoramaEmbedUrl: _virtualTourController.text.trim(),
                ),
              ],
            )
          : null,
      virtualTourUrl: _virtualTourController.text.trim().isNotEmpty ? _virtualTourController.text.trim() : null,
      model3DUrl: _model3DController.text.trim().isNotEmpty ? _model3DController.text.trim() : null,
      arModelUrl: _arModelController.text.trim().isNotEmpty ? _arModelController.text.trim() : null,
      projectName: title,
      floorNumber: 5,
      totalFloors: 24,
      parkingSlots: 2,
      constructionStatus: _selectedPossession,
      contactPreference: 'WhatsApp & Call',
      viewsCount: 0,
      enquiriesCount: 0,
      siteVisitsCount: 0,
      leadsCount: 0,
      mediaList: _propertyImageDocs.asMap().entries.map<PropertyMediaItem>((e) => PropertyMediaItem(
        id: e.value.id,
        propertyId: propId,
        url: e.value.fileUrl,
        type: PropertyMediaType.image,
        caption: 'Property Photo ${e.key + 1}',
        sortOrder: e.key,
      )).toList(),
    );

    // Save submission into PropertyStateService
    PropertyStateService.instance.addDealerPropertySubmission(newProperty);

    // Sync to Supabase Backend
    SupabaseService.instance.submitDealerProperty(
      newProperty,
      dealerId: dealerId,
      dealerName: dealerName,
      dealerPhone: dealerPhone,
      dealerEmail: dealerEmail,
    );

    // Send Dealer Notification
    DealerLeadService.instance.sendNotification(
      dealerId: dealerId,
      type: DealerNotificationType.newEnquiry,
      title: 'Property Submitted for Review ⏳',
      message: 'Your listing "$title" was submitted and is currently pending verification by PropZen Admin.',
      propertyId: newProperty.id,
      propertyTitle: newProperty.title,
    );

    setState(() => _isSubmitting = false);

    // Show Required Success Screen
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldSuccess.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.checkCircle2, color: AppTheme.emeraldSuccess, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                'Property Submitted Successfully',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Your property has been submitted for verification.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Property ID:', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                        Text(newProperty.id, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Listing Status:', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFF59E0B)),
                          ),
                          child: Text(
                            'Pending Verification',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFB45309)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => PropertyDetailsScreen(property: newProperty, propertyId: newProperty.id),
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.eye, size: 16),
                  label: Text('View My Property', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 0)),
                      (r) => false,
                    );
                  },
                  icon: const Icon(LucideIcons.home, size: 16),
                  label: Text('Back to Home', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: const BorderSide(color: AppTheme.borderLight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // UI BUILDERS
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    // 1. Authentication Gate
    if (!UserSession.isLoggedIn) {
      return Scaffold(
        backgroundColor: AppTheme.pageBackground,
        appBar: AppBar(
          title: Text('List Your Property', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderLight),
                  boxShadow: AppTheme.softCardShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryViolet.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.lock, color: AppTheme.primaryViolet, size: 44),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Sign In Required',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'To list a property on PropZen, please sign in or create an account. Your listing will be securely tied to your profile.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const DualAuthScreen(redirectRoute: AppRoutes.listProperty),
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.logIn, size: 18),
                        label: Text('Sign In / Register', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryViolet,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 0)),
                            (r) => false,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppTheme.borderLight),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Back to Home', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // 2. Email Verification Gate
    if (!UserSession.isEmailVerified) {
      return EmailVerificationGateScreen(
        redirectRoute: AppRoutes.listProperty,
        onVerified: () {
          setState(() {});
        },
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        title: Text('List Your Property', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress Indicator
                Row(
                  children: List.generate(_totalSteps, (index) {
                    final isDone = index < _currentStep;
                    final isCurr = index == _currentStep;
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: isDone
                              ? AppTheme.emeraldSuccess
                              : (isCurr ? AppTheme.primaryViolet : AppTheme.borderLight),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Text('Step ${_currentStep + 1} of $_totalSteps', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryViolet)),
                const SizedBox(height: 16),

                // Step Body
                _buildCurrentStep(),

                const SizedBox(height: 24),

                // Navigation Buttons
                Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _currentStep--),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppTheme.borderLight),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Previous', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryViolet,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSubmitting
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Submitting...', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                                ],
                              )
                            : Text(
                                _currentStep == _totalSteps - 1 ? 'Submit Property' : 'Continue',
                                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Center(
                  child: TextButton.icon(
                    onPressed: _isDraftSaving || _isSubmitting ? null : _saveDraft,
                    icon: const Icon(LucideIcons.save, size: 15, color: AppTheme.primaryViolet),
                    label: Text(
                      _isDraftSaving ? 'Saving Draft...' : 'Save as Draft',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryViolet),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Basic();
      case 1:
        return _buildStep2Location();
      case 2:
        return _buildStep3Price();
      case 3:
        return _buildStep4Config();
      case 4:
        return _buildStep5Amenities();
      case 5:
        return _buildStep6Documents();
      case 6:
        return _buildStep7Preview();
      default:
        return const SizedBox.shrink();
    }
  }

  // --- STEP 1: Basic Details ---
  Widget _buildStep1Basic() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Basic Property Details'),
        const SizedBox(height: 14),
        Text('Property Title / Project Name *', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: _titleController,
          style: GoogleFonts.inter(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. Godrej Tropical Isle - Luxury 3 BHK',
            errorText: _titleError,
          ),
        ),
        const SizedBox(height: 16),
        Text('Property Category', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          items: ['Residential', 'Commercial', 'Industrial', 'Agricultural', 'PG/Co-living'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (val) => setState(() => _selectedCategory = val ?? 'Residential'),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Detailed Description *', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _descController,
              builder: (_, val, __) {
                final len = val.text.length;
                return Text(
                  '$len / 2000',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: len > 2000 ? AppTheme.coralDanger : AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _descController,
          maxLines: 4,
          style: GoogleFonts.inter(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Describe key highlights, floor views, orientation, specifications (min 30 characters)...',
            errorText: _descError,
          ),
        ),
      ],
    );
  }

  // --- STEP 2: Location ---
  Widget _buildStep2Location() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Location & Map Placement'),
        const SizedBox(height: 14),
        Text('City / Micro-Market *', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedCity,
          items: ['Noida', 'Greater Noida', 'Yamuna Expressway', 'Gurgaon', 'Delhi', 'Ghaziabad', 'Faridabad'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (val) => setState(() => _selectedCity = val ?? 'Noida'),
        ),
        const SizedBox(height: 16),
        Text('Sector / Locality *', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: _sectorController,
          style: GoogleFonts.inter(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. Sector 150 or Noida Extension',
            errorText: _sectorError,
          ),
        ),
        const SizedBox(height: 16),
        Text('State *', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedState,
          items: _stateOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (val) => setState(() => _selectedState = val ?? 'Uttar Pradesh'),
        ),
        const SizedBox(height: 16),
        Text('Complete Address & Landmark *', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: _addressController,
          style: GoogleFonts.inter(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. Tower 4, Sector 150, Noida Expressway (min 10 characters)',
            errorText: _addressError,
          ),
        ),
        const SizedBox(height: 16),
        Text('Pin Code (6 digits) *', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: _pincodeController,
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. 201310',
            errorText: _pincodeError,
          ),
        ),
        if (_pinAutoDetectNotice != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(LucideIcons.alertTriangle, size: 14, color: Color(0xFFD97706)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _pinAutoDetectNotice!,
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFD97706), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () async {
            final loc = await Navigator.of(context).push<LocationResult>(
              MaterialPageRoute(
                builder: (_) => LocationPickerScreen(
                  initialLatitude: _latitude,
                  initialLongitude: _longitude,
                  initialAddress: _addressController.text,
                ),
              ),
            );
            if (loc != null) {
              setState(() {
                _latitude = loc.latitude;
                _longitude = loc.longitude;
                _placeId = loc.placeId;
                _hasSelectedMapLocation = true;
                if (loc.address.isNotEmpty) _addressController.text = loc.address;
                if (loc.locality.isNotEmpty) _sectorController.text = loc.locality;
                if (loc.city.isNotEmpty) _selectedCity = loc.city;

                // Auto PIN detection check
                final pinCandidate = loc.postalCode.trim();
                if (pinCandidate.isNotEmpty && RegExp(r'^\d{6}$').hasMatch(pinCandidate)) {
                  _pincodeController.text = pinCandidate;
                  _pinAutoDetectNotice = null;
                } else {
                  _pinAutoDetectNotice = 'Unable to detect PIN code. Please enter it manually.';
                }
              });
            }
          },
          icon: Icon(_hasSelectedMapLocation ? LucideIcons.mapPin : LucideIcons.map, color: AppTheme.primaryViolet),
          label: Text(_hasSelectedMapLocation ? 'Location Set: ($_latitude, $_longitude)' : 'Pin Precise Location on Map', style: GoogleFonts.inter(color: AppTheme.primaryViolet, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  // --- STEP 3: Price & Type ---
  Widget _buildStep3Price() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Pricing & Property Type'),
        const SizedBox(height: 14),
        Text('Property Type *', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedType,
          items: ['Apartment', 'Flat', 'Plot', 'Villa', 'Office Space', 'Retail Shop', 'Warehouse', 'Agricultural Land'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (val) {
            setState(() {
              _selectedType = val ?? 'Apartment';
              if (!FormValidators.isBhkRequired(_selectedType)) {
                _bhkError = null;
              }
            });
          },
        ),
        const SizedBox(height: 16),
        Text('Asking Price (in Crores ₹) *', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: _priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.inter(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. 1.85',
            errorText: _priceError,
          ),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _priceController,
          builder: (_, val, __) {
            final parsed = double.tryParse(val.text.trim());
            if (parsed != null && parsed > 0) {
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Formatted Price: ₹ $parsed Cr',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryViolet),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        const SizedBox(height: 16),
        Text('Super Built-Up Area *', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _sqftController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g. 1850',
                  errorText: _areaError,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                value: _selectedAreaUnit,
                items: _areaUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (val) => setState(() => _selectedAreaUnit = val ?? 'sq ft'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Carpet Area (Optional)', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        TextField(controller: _carpetSqftController, keyboardType: TextInputType.number, style: GoogleFonts.inter(color: AppTheme.textPrimary), decoration: const InputDecoration(hintText: 'e.g. 1550')),
      ],
    );
  }

  // --- STEP 4: Configuration ---
  Widget _buildStep4Config() {
    final requiresBhk = FormValidators.isBhkRequired(_selectedType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Configuration & Possession'),
        const SizedBox(height: 14),

        if (requiresBhk) ...[
          Text('BHK Configuration *', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedBhk,
            items: ['1 BHK', '2 BHK', '3 BHK', '4 BHK', '5+ BHK', 'Studio'].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
            onChanged: (val) => setState(() => _selectedBhk = val ?? '3 BHK'),
            decoration: InputDecoration(errorText: _bhkError),
          ),
          const SizedBox(height: 16),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSubtle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.info, size: 16, color: AppTheme.primaryViolet),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'BHK Configuration is not applicable for $_selectedType.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],

        Text('Bathrooms *', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedBathrooms,
          items: _bathroomOptions.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
          onChanged: (val) => setState(() => _selectedBathrooms = val ?? '2'),
          decoration: InputDecoration(errorText: _bathroomError),
        ),
        const SizedBox(height: 16),
        Text('Furnishing Status', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedFurnishing,
          items: ['Fully Furnished', 'Semi-Furnished', 'Unfurnished'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
          onChanged: (val) => setState(() => _selectedFurnishing = val ?? 'Semi-Furnished'),
        ),
        const SizedBox(height: 16),
        Text('Possession Status', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedPossession,
          items: ['Ready to Move', 'Under Construction', 'Upcoming Launch', 'Immediate'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
          onChanged: (val) => setState(() => _selectedPossession = val ?? 'Ready to Move'),
        ),
      ],
    );
  }

  // --- STEP 5: Amenities ---
  Widget _buildStep5Amenities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Amenities & Features'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _allAmenities.map((a) {
            final isSel = _selectedAmenities.contains(a);
            return FilterChip(
              label: Text(a),
              selected: isSel,
              selectedColor: AppTheme.primaryViolet,
              backgroundColor: AppTheme.surfaceSubtle,
              labelStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                color: isSel ? Colors.white : AppTheme.textSecondary,
              ),
              onSelected: (sel) {
                setState(() {
                  if (sel) {
                    _selectedAmenities.add(a);
                  } else {
                    _selectedAmenities.remove(a);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- STEP 6: Real File Picker & Verification Documents ---
  Widget _buildStep6Documents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Verification Documents & RERA'),
        Text('Upload genuine project compliance files for admin verification', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
        const SizedBox(height: 16),

        Text('RERA Project Registration ID', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        TextField(controller: _reraController, style: GoogleFonts.inter(color: AppTheme.textPrimary), decoration: const InputDecoration(hintText: 'e.g. UPRERAPRJ887766')),
        const SizedBox(height: 20),

        // 1. RERA Registration Certificate Upload Card
        _buildDocumentUploadCard(
          title: 'RERA Registration Certificate',
          subtitle: 'PDF, JPG, PNG (Max 10 MB)',
          icon: LucideIcons.fileCheck,
          doc: _reraDoc,
          isUploading: _isUploadingRera,
          errorMessage: _uploadErrorRera,
          onTapUpload: _pickAndUploadRera,
          onRemove: _removeReraDoc,
        ),

        const SizedBox(height: 14),

        // 2. Master Floor Plan Upload Card
        _buildDocumentUploadCard(
          title: 'Master Floor Plan (2D/3D Blueprint)',
          subtitle: 'PDF, JPG, PNG (Max 10 MB)',
          icon: LucideIcons.layout,
          doc: _floorPlanDoc,
          isUploading: _isUploadingFloorPlan,
          errorMessage: _uploadErrorFloorPlan,
          onTapUpload: _pickAndUploadFloorPlan,
          onRemove: _removeFloorPlanDoc,
        ),

        const SizedBox(height: 14),

        // 3. Property Photos (Multiple)
        _buildPhotosUploadSection(),

        const SizedBox(height: 20),

        // 4. Property Video System (YouTube Only)
        _buildYouTubeVideoSection(),

        const SizedBox(height: 20),

        // 5. Optional Visualization Ecosystem Links
        _buildSectionHeader('Interactive Visualization Links (Optional)'),
        Text('Add verified 360° virtual tours, 3D models or AR assets to give buyers an immersive preview',
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
        const SizedBox(height: 12),

        Text('360° Virtual Tour Embed URL (Kuula / Matterport)',
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: _virtualTourController,
          style: GoogleFonts.inter(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'https://kuula.co/share/...',
            prefixIcon: Icon(LucideIcons.glasses, size: 18),
          ),
        ),
        const SizedBox(height: 14),

        Text('Interactive 3D Model URL / Sketchfab Model ID',
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: _model3DController,
          style: GoogleFonts.inter(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'https://sketchfab.com/models/... or Model UID',
            prefixIcon: Icon(LucideIcons.box, size: 18),
          ),
        ),
        const SizedBox(height: 14),

        Text('AR Asset GLB / USDZ URL (Android / iOS AR Placement)',
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: _arModelController,
          style: GoogleFonts.inter(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'https://.../model.glb',
            prefixIcon: Icon(LucideIcons.scan, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required PropertyDocument? doc,
    required bool isUploading,
    required String? errorMessage,
    required VoidCallback onTapUpload,
    required VoidCallback onRemove,
  }) {
    final isUploaded = doc != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUploaded
              ? AppTheme.emeraldSuccess.withOpacity(0.5)
              : (errorMessage != null ? AppTheme.coralDanger : AppTheme.borderLight),
          width: isUploaded ? 1.5 : 1.0,
        ),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isUploading ? null : onTapUpload,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isUploaded
                            ? AppTheme.emeraldSuccess.withOpacity(0.12)
                            : AppTheme.primaryViolet.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isUploaded ? LucideIcons.checkCircle2 : icon,
                        color: isUploaded ? AppTheme.emeraldSuccess : AppTheme.primaryViolet,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          if (isUploaded) ...[
                            Text(
                              'Selected file: ${doc.fileName} (${doc.formattedSize})',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.emeraldSuccess),
                            ),
                          ] else ...[
                            Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                          ],
                        ],
                      ),
                    ),
                    if (isUploading) ...[
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryViolet),
                      ),
                    ] else if (isUploaded) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.refreshCw, size: 16, color: AppTheme.primaryViolet),
                            tooltip: 'Replace File',
                            onPressed: onTapUpload,
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.redAccent),
                            tooltip: 'Remove File',
                            onPressed: onRemove,
                          ),
                        ],
                      ),
                    ] else ...[
                      const Icon(LucideIcons.uploadCloud, color: AppTheme.primaryViolet, size: 20),
                    ],
                  ],
                ),

                // Uploading progress text
                if (isUploading) ...[
                  const SizedBox(height: 10),
                  Text('Uploading to Supabase Storage...', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.primaryViolet, fontStyle: FontStyle.italic)),
                ],

                // Error Message banner
                if (errorMessage != null && !isUploading) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.coralDanger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.coralDanger.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.alertCircle, color: AppTheme.coralDanger, size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Upload failed: $errorMessage', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.coralDanger, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildYouTubeVideoSection() {
    final ytVal = YouTubeMediaService.validateAndExtract(_youtubeUrlController.text.trim());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ytVal.isValid ? const Color(0xFFFF0000).withOpacity(0.4) : AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0000).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.youtube, color: Color(0xFFFF0000), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Property Video Walkthrough (YouTube Only)',
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
                    Text('We do not store large video files in storage. Enter an official YouTube link.',
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _youtubeUrlController,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'https://www.youtube.com/watch?v=... or https://youtu.be/...',
              prefixIcon: const Icon(LucideIcons.video, size: 18),
              suffixIcon: _youtubeUrlController.text.isNotEmpty
                  ? (ytVal.isValid
                      ? const Icon(LucideIcons.checkCircle, color: AppTheme.emeraldSuccess)
                      : const Icon(LucideIcons.alertCircle, color: AppTheme.coralDanger))
                  : null,
            ),
          ),
          if (_youtubeUrlController.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            if (ytVal.isValid && ytVal.videoId != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        ytVal.thumbnailUrl ?? '',
                        width: 70,
                        height: 45,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(width: 70, height: 45, color: Colors.black26),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('✓ Valid YouTube Video ID: ${ytVal.videoId}',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF15803D))),
                          Text('Thumbnail preview verified. Official player will be loaded on demand.',
                              style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF166534))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                ytVal.errorMessage ?? 'Please enter a valid YouTube video URL (e.g. youtube.com or youtu.be).',
                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.coralDanger),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPhotosUploadSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.primaryViolet.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(LucideIcons.image, color: AppTheme.primaryViolet, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Property Photos (${_propertyImageDocs.length} uploaded)', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
                    Text('Auto-optimized & multi-tier compressed (JPG, PNG, WebP up to 15 MB)', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              if (_isUploadingPhotos)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryViolet)),
                    const SizedBox(width: 8),
                    Text(_uploadStageText.isNotEmpty ? _uploadStageText : 'Optimizing...', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.primaryViolet, fontWeight: FontWeight.w600)),
                  ],
                )
              else
                ElevatedButton.icon(
                  onPressed: _pickAndUploadPhotos,
                  icon: const Icon(LucideIcons.plus, size: 14),
                  label: const Text('Add Photos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
            ],
          ),

          if (_imageError != null && _propertyImageDocs.isEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.coralDanger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.coralDanger.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertCircle, color: AppTheme.coralDanger, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _imageError!,
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.coralDanger, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_uploadErrorPhotos != null && !_isUploadingPhotos) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.coralDanger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.coralDanger.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertCircle, color: AppTheme.coralDanger, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Upload Failed: $_uploadErrorPhotos',
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.coralDanger, fontWeight: FontWeight.w500),
                    ),
                  ),
                  TextButton(
                    onPressed: _pickAndUploadPhotos,
                    child: const Text('Retry', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                  ),
                ],
              ),
            ),
          ],

          // Uploaded Photos Grid / Cards with Reorder & Cover Select
          if (_propertyImageDocs.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Photo Management (Drag / Order & Set Cover Image)',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(_propertyImageDocs.length, (idx) {
                final doc = _propertyImageDocs[idx];
                final isCover = idx == _coverImageIndex;

                return Container(
                  width: 175,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isCover ? const Color(0xFFF0FDF4) : AppTheme.surfaceSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isCover ? const Color(0xFF86EFAC) : AppTheme.borderLight, width: isCover ? 1.5 : 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: doc.bytes != null
                                ? Image.memory(doc.bytes!, height: 80, width: double.infinity, fit: BoxFit.cover)
                                : Image.network(doc.fileUrl, height: 80, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 80, color: Colors.black12)),
                          ),
                          if (isCover)
                            Positioned(
                              top: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFF15803D), borderRadius: BorderRadius.circular(4)),
                                child: Text('★ COVER', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: InkWell(
                              onTap: () => _removePhotoDoc(idx),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                child: const Icon(LucideIcons.x, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(doc.fileName, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${doc.formattedSize} • Optimized', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.emeraldSuccess)),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              InkWell(
                                onTap: idx > 0 ? () => _movePhotoLeft(idx) : null,
                                child: Icon(LucideIcons.arrowLeft, size: 14, color: idx > 0 ? AppTheme.textPrimary : Colors.black12),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: idx < _propertyImageDocs.length - 1 ? () => _movePhotoRight(idx) : null,
                                child: Icon(LucideIcons.arrowRight, size: 14, color: idx < _propertyImageDocs.length - 1 ? AppTheme.textPrimary : Colors.black12),
                              ),
                            ],
                          ),
                          if (!isCover)
                            InkWell(
                              onTap: () => _setCoverImage(idx),
                              child: Text('Make Cover', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  // --- STEP 7: Review & Mandatory Dealer Declarations ---
  Widget _buildStep7Preview() {
    final hasError = (_highlightDeclarationsError && !_allMandatoryDeclarationsAccepted) || _termsError != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Review Listing Before Submission'),
        const SizedBox(height: 14),

        // User Type Selector
        Text('Listing As (User Type) *', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Row(
          children: ['Owner', 'Dealer', 'Builder'].map((role) {
            final isSel = _selectedUserType == role;
            return Expanded(
              child: InkWell(
                onTap: () => setState(() => _selectedUserType = role),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSel ? AppTheme.primaryViolet : AppTheme.surfaceSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSel ? AppTheme.primaryViolet : AppTheme.borderLight),
                  ),
                  child: Center(
                    child: Text(
                      role,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSel ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_selectedUserType != 'Owner') ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.shieldAlert, size: 16, color: Color(0xFFB45309)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Listing status remains PENDING_VERIFICATION until actual verification is completed by admin.',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF92400E), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),

        // Contact Information
        Text('Contact Person Details', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 10),
        Text('Name *', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: _nameController,
          style: GoogleFonts.inter(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Full Name',
            errorText: _contactNameError,
          ),
        ),
        const SizedBox(height: 12),
        Text('Phone Number (10 digits) *', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: GoogleFonts.inter(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. 9876543210',
            errorText: _contactPhoneError,
          ),
        ),
        const SizedBox(height: 12),
        Text('Email Address *', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.inter(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. user@example.com',
            errorText: _contactEmailError,
          ),
        ),
        const SizedBox(height: 20),

        // Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderLight),
            boxShadow: AppTheme.softCardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_titleController.text.isNotEmpty ? _titleController.text : 'Untitled Property', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 4),
              Text('${_sectorController.text.isNotEmpty ? _sectorController.text : "Location"}, $_selectedCity', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('₹ ${_priceController.text.isNotEmpty ? _priceController.text : "0.00"} Cr', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                  Text('$_selectedBhk • ${_sqftController.text.isNotEmpty ? _sqftController.text : "0"} $_selectedAreaUnit', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
              const Divider(color: AppTheme.borderLight, height: 24),
              Text('RERA Registration: ${_reraController.text.isNotEmpty ? _reraController.text : "Pending Declaration"}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.emeraldSuccess, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(_reraDoc != null ? LucideIcons.checkCircle : LucideIcons.circle, size: 14, color: _reraDoc != null ? AppTheme.emeraldSuccess : AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Text(_reraDoc != null ? 'RERA Certificate: ${_reraDoc!.fileName}' : 'RERA Certificate: Not attached', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(_floorPlanDoc != null ? LucideIcons.checkCircle : LucideIcons.circle, size: 14, color: _floorPlanDoc != null ? AppTheme.emeraldSuccess : AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Text(_floorPlanDoc != null ? 'Master Floor Plan: ${_floorPlanDoc!.fileName}' : 'Master Floor Plan: Not attached', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(_propertyImageDocs.isNotEmpty ? LucideIcons.checkCircle : LucideIcons.circle, size: 14, color: _propertyImageDocs.isNotEmpty ? AppTheme.emeraldSuccess : AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Text('Uploaded Photos: ${_propertyImageDocs.length} images', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Dedicated Terms & Conditions & Declaration Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hasError ? AppTheme.coralDanger : AppTheme.primaryViolet.withOpacity(0.35),
              width: hasError ? 2.0 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: hasError ? AppTheme.coralDanger.withOpacity(0.12) : AppTheme.primaryViolet.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryViolet.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.shieldCheck, color: AppTheme.primaryViolet, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Before You Submit', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        Text('Terms & Conditions & Declaration', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryViolet)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Please review and confirm the following declarations before submitting your property.',
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),

              // View Terms Action Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.fileText, color: AppTheme.primaryViolet, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Read Propzen Dealer Terms & Conditions (v${DealerTermsConfig.currentVersion})',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const DealerTermsAndConditionsScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        foregroundColor: AppTheme.primaryViolet,
                        side: const BorderSide(color: AppTheme.primaryViolet),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('View Terms', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              if (hasError)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.coralDanger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.coralDanger.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertCircle, color: AppTheme.coralDanger, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _termsError ?? 'Please accept all required declarations before submitting your property.',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.coralDanger),
                        ),
                      ),
                    ],
                  ),
                ),

              // Mandatory Two Checkboxes required by Requirement 17
              _buildDeclarationTile(
                title: 'Legal Right / Authorization',
                text: 'I confirm that I have the legal right/authorization to list this property and that the information provided is accurate.',
                value: _confirmLegalRight,
                onChanged: (v) => setState(() {
                  _confirmLegalRight = v ?? false;
                  _declarationAccuracy = _confirmLegalRight;
                  _declarationAuthorization = _confirmLegalRight;
                  if (_confirmLegalRight && _agreeTermsAndPolicy) {
                    _termsError = null;
                  }
                }),
              ),
              _buildDeclarationTile(
                title: 'Terms & Policy Agreement',
                text: 'I agree to PropZen Terms & Conditions and Property Listing Policy.',
                value: _agreeTermsAndPolicy,
                onChanged: (v) => setState(() {
                  _agreeTermsAndPolicy = v ?? false;
                  _declarationTerms = _agreeTermsAndPolicy;
                  if (_confirmLegalRight && _agreeTermsAndPolicy) {
                    _termsError = null;
                  }
                }),
              ),

              const Divider(height: 16, color: AppTheme.borderLight),

              // Additional Declarations
              _buildDeclarationTile(
                title: 'Content Rights',
                text: 'I own the copyright or have valid permission to use all uploaded images, floor plans, and media files.',
                value: _declarationContentRights,
                onChanged: (v) => setState(() => _declarationContentRights = v ?? false),
              ),
              _buildDeclarationTile(
                title: 'Fair Pricing',
                text: 'The asking price represents the genuine current market valuation without hidden escalations or fake discount claims.',
                value: _declarationPricing,
                onChanged: (v) => setState(() => _declarationPricing = v ?? false),
              ),
              _buildDeclarationTile(
                title: 'Admin Verification Consent',
                text: 'I acknowledge that Propzen Admin will review this listing before public display and may request additional legal documents.',
                value: _declarationReview,
                onChanged: (v) => setState(() => _declarationReview = v ?? false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeclarationTile({
    required String title,
    required String text,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              activeColor: AppTheme.primaryViolet,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: onChanged,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                    color: value ? AppTheme.textPrimary : AppTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary));
  }
}
