// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'insurance_product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InsuranceProduct _$InsuranceProductFromJson(Map<String, dynamic> json) =>
    InsuranceProduct(
      productId: (json['productId'] as num?)?.toInt(),
      productName: json['productName'] as String?,
      companyName: json['companyName'] as String?,
      insuranceType: json['insuranceType'] as String?,
      premium: json['premium'],
      totalScore: (json['totalScore'] as num?)?.toDouble(),
      coverageAmount: json['coverageAmount'],
      coveragePeriod: json['coveragePeriod'] as String?,
      coverageContent: json['coverageContent'],
      productType: json['productType'] as String?,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$InsuranceProductToJson(InsuranceProduct instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'productName': instance.productName,
      'companyName': instance.companyName,
      'insuranceType': instance.insuranceType,
      'premium': instance.premium,
      'totalScore': instance.totalScore,
      'coverageAmount': instance.coverageAmount,
      'coveragePeriod': instance.coveragePeriod,
      'coverageContent': instance.coverageContent,
      'productType': instance.productType,
      'additionalData': instance.additionalData,
    };
