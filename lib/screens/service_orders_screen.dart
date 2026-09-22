import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/colors.dart';
import '../core/di/injection_container.dart';
import '../features/execution/data/models/service_order_model.dart';
import '../features/execution/presentation/bloc/service_orders/service_orders_bloc.dart';
import '../features/execution/presentation/bloc/service_orders/service_orders_event.dart';
import '../features/execution/presentation/bloc/service_orders/service_orders_state.dart';
import 'service_detail_screen.dart';

class ServiceOrdersScreen extends StatelessWidget {
  const ServiceOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ServiceOrdersBloc>(
      create: (_) =>
          getIt<ServiceOrdersBloc>()..add(const FetchServiceOrdersEvent()),
      child: const _ServiceOrdersView(),
    );
  }
}

class _ServiceOrdersView extends StatefulWidget {
  const _ServiceOrdersView();

  @override
  State<_ServiceOrdersView> createState() => _ServiceOrdersViewState();
}

class _ServiceOrdersViewState extends State<_ServiceOrdersView> {
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Buscar por cliente, OS...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.toLowerCase();
                  });
                },
              )
            : const Text('Ordens de Serviço',
                style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchQuery = '';
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context
                  .read<ServiceOrdersBloc>()
                  .add(const FetchServiceOrdersEvent());
            },
          ),
        ],
      ),
      body: BlocBuilder<ServiceOrdersBloc, ServiceOrdersState>(
        builder: (context, state) {
          if (state is ServiceOrdersLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ServiceOrdersError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context
                            .read<ServiceOrdersBloc>()
                            .add(const FetchServiceOrdersEvent());
                      },
                      child: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is ServiceOrdersLoaded) {
            var orders = state.orders;
            if (_searchQuery.isNotEmpty) {
              orders = orders.where((o) {
                final client = o.cliente?.nome.toLowerCase() ?? '';
                final numOs = o.numeroOs.toLowerCase();
                final tipo = o.tipoServicoNome?.toLowerCase() ?? '';
                return client.contains(_searchQuery) ||
                    numOs.contains(_searchQuery) ||
                    tipo.contains(_searchQuery);
              }).toList();
            }

            if (orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.assignment_outlined,
                        size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'Nenhuma OS encontrada com "$_searchQuery".'
                          : 'Nenhuma Ordem de Serviço alocada para você.',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<ServiceOrdersBloc>()
                    .add(const FetchServiceOrdersEvent());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final os = orders[index];
                  return _buildOrderCard(context, os);
                },
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, ServiceOrderModel os) {
    Color indicatorColor = AppColors.primary;
    if (os.status == 'FINALIZADO') {
      indicatorColor = AppColors.success;
    } else if (os.status == 'EM_ANDAMENTO') {
      indicatorColor = AppColors.info;
    } else if (os.status == 'CANCELADO' || os.status == 'RECUSADO') {
      indicatorColor = AppColors.error;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceDetailScreen(servicoId: os.id),
          ),
        ).then((_) {
          if (context.mounted) {
            context
                .read<ServiceOrdersBloc>()
                .add(const FetchServiceOrdersEvent());
          }
        });
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        elevation: 0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 6,
              height: 130,
              color: indicatorColor,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            os.cliente?.nome ?? 'Cliente',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          os.numeroOs,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      os.cliente?.endereco ?? 'Endereço não informado',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      os.tipoServicoNome?.isNotEmpty == true
                          ? os.tipoServicoNome!
                          : (os.descricao ?? 'Atendimento Técnico'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 12, thickness: 0.5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Status: ${os.status}',
                          style: TextStyle(
                            color: indicatorColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Etapas: ${os.etapasClosed}/${os.etapasTotal}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
