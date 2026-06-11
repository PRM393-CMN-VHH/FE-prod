import 'package:flutter/material.dart';
import 'package:prm393/models/category.dart';
import 'package:prm393/models/product.dart';
import 'package:prm393/models/user.dart';
import 'package:prm393/services/api_service.dart';
import 'package:prm393/theme/app_theme.dart';
import 'package:prm393/utils/currency_formatter.dart';
import 'package:prm393/utils/error_translator.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryColor,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: "Tổng quan"),
            Tab(text: "Đơn hàng"),
            Tab(text: "Sản phẩm"),
            Tab(text: "Combo"),
            Tab(text: "User"),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _AdminDashboardTab(),
              _AdminOrdersTab(),
              _AdminProductsTab(),
              _AdminComboTab(),
              _AdminUsersTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminDashboardTab extends StatefulWidget {
  const _AdminDashboardTab();

  @override
  State<_AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<_AdminDashboardTab> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService().getAdminDashboard();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = ApiService().getAdminDashboard();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Loading();
        }
        if (snapshot.hasError) return _ErrorState(error: snapshot.error!);
        final data = snapshot.data!;
        final stats = [
          ("Khách hàng", data['totalUsers']),
          ("Sản phẩm", data['totalProducts']),
          ("Đơn hàng", data['totalOrders']),
          ("Pending", data['pendingCount']),
          ("Confirmed", data['confirmedCount']),
          ("Shipped", data['shippedCount']),
          ("Delivered", data['deliveredCount']),
          ("Cancelled", data['cancelledCount']),
        ];
        return RefreshIndicator(
          onRefresh: _refresh,
          color: AppTheme.primaryColor,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: stats.length,
            itemBuilder: (_, index) => Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      stats[index].$1,
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${stats[index].$2 ?? 0}",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AdminOrdersTab extends StatefulWidget {
  const _AdminOrdersTab();

  @override
  State<_AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<_AdminOrdersTab> {
  final _emailController = TextEditingController();
  String? _status;
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _load() {
    return ApiService().getAdminOrders(
      email: _emailController.text.trim(),
      status: _status,
    );
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _updateStatus(int orderId, String status) async {
    try {
      await ApiService().updateAdminOrderStatus(
        orderId: orderId,
        status: status,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đã cập nhật trạng thái")));
      _refresh();
    } catch (e) {
      if (!mounted) return;
      _showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Lọc email",
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (_) => _refresh(),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String?>(
                value: _status,
                hint: const Text("Trạng thái"),
                items: const [
                  DropdownMenuItem(value: null, child: Text("Tất cả")),
                  DropdownMenuItem(value: "PENDING", child: Text("PENDING")),
                  DropdownMenuItem(
                    value: "CONFIRMED",
                    child: Text("CONFIRMED"),
                  ),
                  DropdownMenuItem(value: "SHIPPED", child: Text("SHIPPED")),
                  DropdownMenuItem(
                    value: "DELIVERED",
                    child: Text("DELIVERED"),
                  ),
                  DropdownMenuItem(
                    value: "CANCELLED",
                    child: Text("CANCELLED"),
                  ),
                ],
                onChanged: (value) {
                  _status = value;
                  _refresh();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _Loading();
              }
              if (snapshot.hasError) return _ErrorState(error: snapshot.error!);
              final orders = (snapshot.data!['orders'] as List? ?? []);
              if (orders.isEmpty) {
                return const _EmptyState(text: "Không có đơn");
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: orders.length,
                itemBuilder: (_, index) {
                  final order = Map<String, dynamic>.from(orders[index] as Map);
                  final orderId = order['orderId'] ?? order['id'] ?? 0;
                  final currentStatus =
                      order['orderStatus'] ?? order['status'] ?? '';
                  final user = order['user'] is Map
                      ? Map<String, dynamic>.from(order['user'] as Map)
                      : <String, dynamic>{};
                  return Card(
                    elevation: 0,
                    child: ListTile(
                      title: Text("Đơn #$orderId - $currentStatus"),
                      subtitle: Text(
                        "${user['email'] ?? ''}\n${formatVnd((order['totalPrice'] as num? ?? 0).toDouble())}",
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) =>
                            _updateStatus(orderId as int, value),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: "PENDING",
                            child: Text("PENDING"),
                          ),
                          PopupMenuItem(
                            value: "CONFIRMED",
                            child: Text("CONFIRMED"),
                          ),
                          PopupMenuItem(
                            value: "SHIPPED",
                            child: Text("SHIPPED"),
                          ),
                          PopupMenuItem(
                            value: "DELIVERED",
                            child: Text("DELIVERED"),
                          ),
                          PopupMenuItem(
                            value: "CANCELLED",
                            child: Text("CANCELLED"),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AdminProductsTab extends StatefulWidget {
  const _AdminProductsTab();

  @override
  State<_AdminProductsTab> createState() => _AdminProductsTabState();
}

class _AdminProductsTabState extends State<_AdminProductsTab> {
  final _searchController = TextEditingController();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _load() {
    return ApiService().getAdminProducts(
      keyword: _searchController.text.trim(),
    );
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _editProduct([Product? product]) async {
    final saved = await showDialog<Product>(
      context: context,
      builder: (_) => _ProductEditorDialog(product: product),
    );
    if (saved == null) return;
    try {
      if (product == null) {
        await ApiService().addAdminProduct(saved);
      } else {
        await ApiService().editAdminProduct(saved);
      }
      _refresh();
    } catch (e) {
      if (!mounted) return;
      _showError(context, e);
    }
  }

  Future<void> _deleteProduct(int productId) async {
    try {
      await ApiService().deleteAdminProduct(productId);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      _showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: "Tìm sản phẩm",
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (_) => _refresh(),
                ),
              ),
              IconButton(
                onPressed: () => _editProduct(),
                icon: const Icon(Icons.add_circle_outline),
                tooltip: "Thêm sản phẩm",
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _Loading();
              }
              if (snapshot.hasError) return _ErrorState(error: snapshot.error!);
              final products = (snapshot.data!['products'] as List? ?? [])
                  .map((json) => Product.fromJson(json as Map<String, dynamic>))
                  .toList();
              if (products.isEmpty) {
                return const _EmptyState(text: "Không có sản phẩm");
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: products.length,
                itemBuilder: (_, index) {
                  final product = products[index];
                  return Card(
                    elevation: 0,
                    child: ListTile(
                      leading: Image.network(
                        product.imageUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.local_florist),
                      ),
                      title: Text(product.name),
                      subtitle: Text(
                        "${formatVnd(product.price)} - Tồn: ${product.stock}",
                      ),
                      trailing: Wrap(
                        children: [
                          IconButton(
                            onPressed: () => _editProduct(product),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            onPressed: () => _deleteProduct(product.id),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AdminComboTab extends StatefulWidget {
  const _AdminComboTab();

  @override
  State<_AdminComboTab> createState() => _AdminComboTabState();
}

class _AdminComboTabState extends State<_AdminComboTab> {
  late Future<List<Product>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService().getAdminComboProducts();
  }

  void _refresh() {
    setState(() {
      _future = ApiService().getAdminComboProducts();
    });
  }

  Future<void> _openCombo(Product combo) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _ComboDetailScreen(combo: combo)),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Loading();
        }
        if (snapshot.hasError) return _ErrorState(error: snapshot.error!);
        final combos = snapshot.data ?? [];
        if (combos.isEmpty) return const _EmptyState(text: "Không có combo");
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: combos.length,
          itemBuilder: (_, index) {
            final combo = combos[index];
            return Card(
              elevation: 0,
              child: ListTile(
                title: Text(combo.name),
                subtitle: Text(formatVnd(combo.price)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openCombo(combo),
              ),
            );
          },
        );
      },
    );
  }
}

class _AdminUsersTab extends StatefulWidget {
  const _AdminUsersTab();

  @override
  State<_AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<_AdminUsersTab> {
  final _searchController = TextEditingController();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _load() {
    return ApiService().getAdminUsers(search: _searchController.text.trim());
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _toggle(UserModel user) async {
    try {
      if (user.isActive) {
        await ApiService().deactivateAdminUser(int.parse(user.id));
      } else {
        await ApiService().activateAdminUser(int.parse(user.id));
      }
      _refresh();
    } catch (e) {
      if (!mounted) return;
      _showError(context, e);
    }
  }

  Future<void> _updateRole(UserModel user, int roleId) async {
    try {
      await ApiService().updateAdminUserRole(
        userId: int.parse(user.id),
        roleId: roleId,
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      _showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: "Tìm user",
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (_) => _refresh(),
          ),
        ),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _Loading();
              }
              if (snapshot.hasError) return _ErrorState(error: snapshot.error!);
              final users =
                  ((snapshot.data!['users'] ??
                              snapshot.data!['userList'] ??
                              snapshot.data!['content'] ??
                              [])
                          as List)
                      .map(
                        (json) =>
                            UserModel.fromJson(json as Map<String, dynamic>),
                      )
                      .toList();
              if (users.isEmpty) {
                return const _EmptyState(text: "Không có user");
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: users.length,
                itemBuilder: (_, index) {
                  final user = users[index];
                  return Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name.isEmpty
                                          ? user.email
                                          : user.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    Text(
                                      user.email,
                                      style: const TextStyle(
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: user.isActive,
                                onChanged: (_) => _toggle(user),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            initialValue: user.roleId ?? (user.isAdmin ? 1 : 2),
                            decoration: const InputDecoration(
                              labelText: "Role",
                              prefixIcon: Icon(Icons.security_outlined),
                            ),
                            items: const [
                              DropdownMenuItem(value: 1, child: Text("Admin")),
                              DropdownMenuItem(value: 2, child: Text("User")),
                            ],
                            onChanged: (roleId) {
                              if (roleId != null && roleId != user.roleId) {
                                _updateRole(user, roleId);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProductEditorDialog extends StatefulWidget {
  final Product? product;

  const _ProductEditorDialog({this.product});

  @override
  State<_ProductEditorDialog> createState() => _ProductEditorDialogState();
}

class _ProductEditorDialogState extends State<_ProductEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _imageController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _categoryId = 1;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product != null) {
      _nameController.text = product.name;
      _priceController.text = product.price.toStringAsFixed(0);
      _stockController.text = product.stock.toString();
      _imageController.text = product.imageUrl;
      _descriptionController.text = product.description;
      _categoryId = product.categoryId == 0 ? 1 : product.categoryId;
    }
    ApiService().getCategories().then((value) {
      if (!mounted) return;
      setState(() {
        _categories = value;
        if (_categories.isNotEmpty &&
            !_categories.any((category) => category.id == _categoryId)) {
          _categoryId = _categories.first.id;
        }
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final old = widget.product;
    Navigator.pop(
      context,
      Product(
        id: old?.id ?? 0,
        name: _nameController.text.trim(),
        categoryId: _categoryId,
        imageUrl: _imageController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        description: _descriptionController.text.trim(),
        careInstructions: old?.careInstructions ?? '',
        stock: int.parse(_stockController.text.trim()),
        isAvailable: true,
        flowerType: old?.flowerType ?? '',
        color: old?.color ?? '',
        size: old?.size ?? '',
        freshness: old?.freshness ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? "Thêm sản phẩm" : "Sửa sản phẩm"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Tên"),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? "Bắt buộc" : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: "Giá"),
                keyboardType: TextInputType.number,
                validator: (value) => double.tryParse(value ?? '') == null
                    ? "Giá không hợp lệ"
                    : null,
              ),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: "Tồn kho"),
                keyboardType: TextInputType.number,
                validator: (value) => int.tryParse(value ?? '') == null
                    ? "Số không hợp lệ"
                    : null,
              ),
              TextFormField(
                controller: _imageController,
                decoration: const InputDecoration(labelText: "Ảnh URL"),
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Mô tả"),
                maxLines: 2,
              ),
              DropdownButtonFormField<int>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: "Danh mục"),
                items: _categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _categoryId = value);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Hủy"),
        ),
        ElevatedButton(onPressed: _submit, child: const Text("Lưu")),
      ],
    );
  }
}

class _ComboDetailScreen extends StatefulWidget {
  final Product combo;

  const _ComboDetailScreen({required this.combo});

  @override
  State<_ComboDetailScreen> createState() => _ComboDetailScreenState();
}

class _ComboDetailScreenState extends State<_ComboDetailScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService().getAdminComboItems(widget.combo.id);
  }

  void _refresh() {
    setState(() {
      _future = ApiService().getAdminComboItems(widget.combo.id);
    });
  }

  Future<void> _addItem(List products) async {
    final result = await showDialog<(int, int)>(
      context: context,
      builder: (_) => _ComboItemDialog(products: products),
    );
    if (result == null) return;
    try {
      await ApiService().saveAdminComboItem(
        comboId: widget.combo.id,
        productId: result.$1,
        quantity: result.$2,
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      _showError(context, e);
    }
  }

  Future<void> _removeItem(int id) async {
    try {
      await ApiService().removeAdminComboItem(id);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      _showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.combo.name)),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _Loading();
          }
          if (snapshot.hasError) return _ErrorState(error: snapshot.error!);
          final data = snapshot.data!;
          final items =
              (data['comboItems'] ??
                      data['productComboItems'] ??
                      data['items'] ??
                      [])
                  as List;
          final products =
              (data['productList'] ?? data['products'] ?? []) as List;
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              ElevatedButton.icon(
                onPressed: () => _addItem(products),
                icon: const Icon(Icons.add),
                label: const Text("Thêm hoa vào combo"),
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const _EmptyState(text: "Combo chưa có thành phần")
              else
                ...items.map((raw) {
                  final item = Map<String, dynamic>.from(raw as Map);
                  final product = item['component'] is Map
                      ? Map<String, dynamic>.from(item['component'] as Map)
                      : item['product'] is Map
                      ? Map<String, dynamic>.from(item['product'] as Map)
                      : <String, dynamic>{};
                  final id = item['id'] ?? item['comboItemId'] ?? 0;
                  return Card(
                    elevation: 0,
                    child: ListTile(
                      title: Text(
                        product['productName'] ?? product['name'] ?? "Hoa #$id",
                      ),
                      subtitle: Text("Số lượng: ${item['quantity'] ?? 0}"),
                      trailing: IconButton(
                        onPressed: () => _removeItem(id as int),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _ComboItemDialog extends StatefulWidget {
  final List products;

  const _ComboItemDialog({required this.products});

  @override
  State<_ComboItemDialog> createState() => _ComboItemDialogState();
}

class _ComboItemDialogState extends State<_ComboItemDialog> {
  int? _productId;
  final _quantityController = TextEditingController(text: '1');

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Thêm/cập nhật hoa"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            initialValue: _productId,
            decoration: const InputDecoration(labelText: "Hoa đơn"),
            items: widget.products.map((raw) {
              final product = Map<String, dynamic>.from(raw as Map);
              final id = product['productId'] ?? product['id'] ?? 0;
              return DropdownMenuItem(
                value: id as int,
                child: Text(
                  product['productName'] ?? product['name'] ?? "Hoa #$id",
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _productId = value),
          ),
          TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Số lượng"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Hủy"),
        ),
        ElevatedButton(
          onPressed: _productId == null
              ? null
              : () => Navigator.pop(context, (
                  _productId!,
                  int.tryParse(_quantityController.text) ?? 1,
                )),
          child: const Text("Lưu"),
        ),
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.primaryColor),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;

  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          style: const TextStyle(color: AppTheme.textSecondaryColor),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          ErrorTranslator.userMessage(error),
          style: const TextStyle(color: Colors.redAccent),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

void _showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(ErrorTranslator.userMessage(error)),
      backgroundColor: Colors.redAccent,
    ),
  );
}
