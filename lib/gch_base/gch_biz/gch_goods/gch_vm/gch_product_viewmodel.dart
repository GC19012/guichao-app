import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:guichao/gch_base/gch_biz/gch_goods/gch_model/gch_product_model.dart';
import 'package:guichao/gch_base/gch_biz/gch_goods/gch_providers/gch_product_providers.dart';
import 'package:guichao/gch_base/gch_store/gch_db.dart';

part 'gch_product_viewmodel.g.dart';

/// 产品状态
class ProductState {
  final List<ProductEntry> products;
  final bool isLoading;
  final String? error;
  final ProductEntry? selectedProduct;

  const ProductState({
    this.products = const [],
    this.isLoading = false,
    this.error,
    this.selectedProduct,
  });

  ProductState copyWith({
    List<ProductEntry>? products,
    bool? isLoading,
    String? error,
    ProductEntry? selectedProduct,
  }) {
    return ProductState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedProduct: selectedProduct ?? this.selectedProduct,
    );
  }
}

/// 产品ViewModel
@riverpod
class ProductViewModel extends _$ProductViewModel {
  @override
  Future<ProductState> build() async {
    return const ProductState();
  }

  /// 加载所有产品
  Future<void> loadProducts() async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(productRepositoryProvider);
      final result = await repository.getProducts();

      result.fold(
        (error) => state = AsyncValue.error(error, StackTrace.current),
        (products) => state = AsyncValue.data(ProductState(products: products)),
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }


  /// 根据平台获取产品
  Future<void> loadProductsByPlatform(ProductPlatform platform) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(productRepositoryProvider);
      final result = await repository.getProductsByPlatform(platform);

      result.fold(
        (error) => state = AsyncValue.error(error, StackTrace.current),
        (products) => state = AsyncValue.data(ProductState(products: products)),
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// 根据类型获取产品
  Future<void> loadProductsByType(ProductType type) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(productRepositoryProvider);
      final result = await repository.getProductsByType(type);

      result.fold(
        (error) => state = AsyncValue.error(error, StackTrace.current),
        (products) => state = AsyncValue.data(ProductState(products: products)),
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// 创建产品
  Future<void> createProduct(ProductEntriesCompanion product) async {
    try {
      final repository = ref.read(productRepositoryProvider);
      final result = await repository.createProduct(product);

      result.fold(
        (error) => state = AsyncValue.error(error, StackTrace.current),
        (createdProduct) {
          final currentState = state.value ?? const ProductState();
          final updatedProducts = [...currentState.products, createdProduct];
          state = AsyncValue.data(currentState.copyWith(products: updatedProducts));
        },
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// 更新产品
  Future<void> updateProduct(ProductEntriesCompanion product) async {
    try {
      final repository = ref.read(productRepositoryProvider);
      final result = await repository.updateProduct(product);

      result.fold(
        (error) => state = AsyncValue.error(error, StackTrace.current),
        (success) {
          if (success) {
            // 重新加载产品列表
            loadProducts();
          }
        },
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// 删除产品
  Future<void> deleteProduct(int id) async {
    try {
      final repository = ref.read(productRepositoryProvider);
      final result = await repository.deleteProduct(id);

      result.fold(
        (error) => state = AsyncValue.error(error, StackTrace.current),
        (success) {
          if (success) {
            final currentState = state.value ?? const ProductState();
            final updatedProducts = currentState.products.where((p) => p.id != id).toList();
            state = AsyncValue.data(currentState.copyWith(products: updatedProducts));
          }
        },
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// 选择产品
  void selectProduct(ProductEntry product) {
    final currentState = state.value ?? const ProductState();
    state = AsyncValue.data(currentState.copyWith(selectedProduct: product));
  }

  /// 清除选中的产品
  void clearSelectedProduct() {
    final currentState = state.value ?? const ProductState();
    state = AsyncValue.data(currentState.copyWith(selectedProduct: null));
  }

  /// 获取订阅产品
  List<ProductEntry> get subscriptionProducts {
    final currentState = state.value ?? const ProductState();
    return currentState.products.where((p) => p.type == ProductType.subscription).toList();
  }

  /// 获取消耗品
  List<ProductEntry> get consumableProducts {
    final currentState = state.value ?? const ProductState();
    return currentState.products.where((p) => p.type == ProductType.consumable).toList();
  }

  /// 获取非消耗品
  List<ProductEntry> get nonConsumableProducts {
    final currentState = state.value ?? const ProductState();
    return currentState.products.where((p) => p.type == ProductType.nonConsumable).toList();
  }

  /// 获取Android平台产品
  List<ProductEntry> get androidProducts {
    final currentState = state.value ?? const ProductState();
    return currentState.products.where((p) => p.platform == ProductPlatform.android).toList();
  }

  /// 获取iOS平台产品
  List<ProductEntry> get iosProducts {
    final currentState = state.value ?? const ProductState();
    return currentState.products.where((p) => p.platform == ProductPlatform.ios).toList();
  }

}
