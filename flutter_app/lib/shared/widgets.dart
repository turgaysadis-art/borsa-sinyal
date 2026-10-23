// ==========================================
// BORSA SİNYAL FLUTTER - SHARED WIDGETS
// ==========================================
import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget child;
  final bool showBackButton;
  
  const AppScaffold({
    super.key,
    required this.title,
    this.actions,
    required this.child,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: showBackButton,
        actions: actions,
      ),
      body: SafeArea(child: child),
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  
  const LoadingIndicator({super.key, this.size = 24, this.color});
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation(color ?? Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  
  const ErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onErrorContainer),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text('Tekrar Dene', style: TextStyle(color: theme.colorScheme.onErrorContainer)),
            ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: Icon(Icons.close, color: theme.colorScheme.onErrorContainer),
            ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;
  
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)), textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onTapAll;
  final Widget? trailing;
  
  const SectionHeader({
    super.key,
    required this.title,
    this.onTapAll,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          if (onTapAll != null)
            TextButton(onPressed: onTapAll, child: const Text('Tümü'))
          else if (trailing != null)
            trailing!,
        ],
      ),
    );
  }
}

class ShimmerLine extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  
  const ShimmerLine({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 4,
  });

  @override
  State<ShimmerLine> createState() => _ShimmerLineState();
}

class _ShimmerLineState extends State<ShimmerLine> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 1500),
    vsync: this,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment(-1.0 + _controller.value * 2, 0),
            end: Alignment(1.0 + _controller.value * 2, 0),
            colors: [
              theme.colorScheme.surfaceContainerHighest,
              theme.colorScheme.surfaceContainer,
              theme.colorScheme.surfaceContainerHighest,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}