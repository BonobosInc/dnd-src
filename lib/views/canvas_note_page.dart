import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:dnd/configs/colours.dart';
import 'package:dnd/l10n/app_localizations.dart';
import 'package:dnd/classes/profile_manager.dart';
import 'dart:typed_data';
import 'dart:convert';

class CanvasNotePage extends StatefulWidget {
  final ProfileManager profileManager;
  final String? initialData;
  final String? initialTextNotes;
  final String? initialTitle;

  const CanvasNotePage({
    super.key,
    required this.profileManager,
    this.initialData,
    this.initialTextNotes,
    this.initialTitle,
  });

  @override
  CanvasNotePageState createState() => CanvasNotePageState();
}

class CanvasNotePageState extends State<CanvasNotePage> {
  late SignatureController _signatureController;

  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  Color _currentColor = Colors.black;
  double _strokeWidth = 3.0;
  final GlobalKey _canvasKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  bool _showTools = false;
  bool _isDrawingMode = true;
  bool _isErasing = false;
  Uint8List? _loadedImageBytes;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: _strokeWidth,
      penColor: _currentColor,
    );
    if (widget.initialTextNotes != null) {
      _textController.text = widget.initialTextNotes!;
    }
    if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
    if (widget.initialData != null) {
      _loadCanvasData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set default title with localization after context is available
    if (widget.initialTitle == null && _titleController.text.isEmpty) {
      final now = DateTime.now();
      final loc = AppLocalizations.of(context)!;
      _titleController.text =
          '${loc.canvasNote} ${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _loadCanvasData() async {
    try {
      if (widget.initialData != null && widget.initialData!.isNotEmpty) {
        setState(() {
          _loadedImageBytes = base64Decode(widget.initialData!);
        });
      }
    } catch (e) {
      // Error handling - if loading fails, start with empty canvas
      print('Error loading canvas data: $e');
    }
  }

  @override
  void dispose() {
    _signatureController.dispose();
    _textController.dispose();
    _titleController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _recreateController() {
    final oldPoints = _signatureController.points;
    _signatureController.dispose();
    _signatureController = SignatureController(
      penStrokeWidth: _strokeWidth,
      penColor: _isErasing ? Colors.white : _currentColor,
      points: oldPoints,
    );
  }

  void _toggleEraser() {
    setState(() {
      _isErasing = !_isErasing;
      _recreateController();
    });
  }

  void _changeColor() {
    showDialog(
      context: context,
      builder: (context) {
        Color tempColor = _currentColor;
        final loc = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(loc.changeColor),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _currentColor,
              onColorChanged: (color) {
                tempColor = color;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(loc.abort),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _currentColor = tempColor;
                  _isErasing = false;
                  _recreateController();
                });
                Navigator.of(context).pop();
              },
              child: Text(loc.save),
            ),
          ],
        );
      },
    );
  }

  void _changeStrokeWidth() {
    showDialog(
      context: context,
      builder: (context) {
        double tempWidth = _strokeWidth;
        final loc = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(loc.strokeWidth),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: tempWidth,
                    min: 1.0,
                    max: 20.0,
                    divisions: 19,
                    label: tempWidth.toStringAsFixed(0),
                    onChanged: (value) {
                      setDialogState(() {
                        tempWidth = value;
                      });
                    },
                  ),
                  Text('${tempWidth.toStringAsFixed(0)} px'),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(loc.abort),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _strokeWidth = tempWidth;
                  _recreateController();
                });
                Navigator.of(context).pop();
              },
              child: Text(loc.save),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveNote() async {
    try {
      // Get the canvas render box to determine its actual size
      final RenderBox? renderBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
      final Size? canvasSize = renderBox?.size;

      final Uint8List? newDrawing = canvasSize != null
          ? await _signatureController.toPngBytes(width: canvasSize.width.toInt(), height: canvasSize.height.toInt())
          : await _signatureController.toPngBytes();

      // Use new drawing if exists, otherwise keep loaded image
      final Uint8List? canvasData =
          (newDrawing != null && _signatureController.points.isNotEmpty)
          ? newDrawing
          : _loadedImageBytes;

      final String? canvasBase64 =
          canvasData != null ? base64Encode(canvasData) : null;
      final String textNotes = _textController.text;
      final loc = AppLocalizations.of(context)!;
      final String title = _titleController.text.trim().isEmpty
          ? loc.canvasNote
          : _titleController.text;

      // Save to database using profile manager
      // You'll need to add a method to ProfileManager to handle canvas notes

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.notesSaved),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop({
        'canvasData': canvasBase64,
        'textNotes': textNotes,
        'title': title,
      });
    } catch (e) {
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.errorSaving(e.toString())),
          backgroundColor: AppColors.warningColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          width: 200,
          child: TextField(
            controller: _titleController,
            style: const TextStyle(fontSize: 18, color: Colors.white),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: loc.enterTitle,
              hintStyle: const TextStyle(color: Colors.white60),
            ),
          ),
        ),
        backgroundColor: AppColors.appBarColor,
        actions: [
          IconButton(
            icon: Icon(
              _isDrawingMode ? Icons.edit : Icons.brush,
              color: AppColors.accentCyan,
            ),
            onPressed: () {
              setState(() {
                _isDrawingMode = !_isDrawingMode;
              });
            },
            tooltip: _isDrawingMode ? loc.switchToWriting : loc.switchToDrawing,
          ),
          IconButton(
            icon: const Icon(Icons.save, color: Colors.green),
            onPressed: _saveNote,
            tooltip: loc.save,
          ),
        ],
      ),
      body: Container(
        color: AppColors.primaryColor,
        child: Stack(
          children: [
            // Main content area with text and canvas layered
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 5.0,
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    child: Stack(
                      children: [
                        // Text area at the bottom
                        Positioned.fill(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16.0),
                            child: TextField(
                              controller: _textController,
                              enabled: !_isDrawingMode,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                              maxLines: null,
                            ),
                          ),
                        ),
                        // Previously saved canvas image
                        if (_loadedImageBytes != null)
                          Positioned.fill(
                            child: Image.memory(
                              _loadedImageBytes!,
                              fit: BoxFit.none,
                              alignment: Alignment.topLeft,
                            ),
                          ),
                        // Canvas overlay - drawing appears on top of text
                        Positioned.fill(
                          child: IgnorePointer(
                            ignoring: !_isDrawingMode,
                            child: Signature(
                              key: _canvasKey,
                              controller: _signatureController,
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_showTools) ..._buildToolButtons(),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _showTools = !_showTools;
              });
            },
            backgroundColor: AppColors.accentCyan,
            child: Icon(_showTools ? Icons.close : Icons.brush),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildToolButtons() {
    final loc = AppLocalizations.of(context)!;
    return [
      // Eraser
      FloatingActionButton(
        heroTag: 'eraser',
        mini: true,
        onPressed: _toggleEraser,
        backgroundColor: _isErasing ? AppColors.warningColor : AppColors.cardColor,
        tooltip: loc.eraser,
        child: Icon(
          Icons.auto_fix_high,
          color: _isErasing ? Colors.white : AppColors.accentCyan,
        ),
      ),
      const SizedBox(height: 8),
      // Color picker
      FloatingActionButton(
        heroTag: 'color',
        mini: true,
        onPressed: _changeColor,
        backgroundColor: _currentColor,
        tooltip: loc.changeColor,
        child: const Icon(Icons.color_lens, color: Colors.white),
      ),
      const SizedBox(height: 8),
      // Stroke width
      FloatingActionButton(
        heroTag: 'stroke',
        mini: true,
        onPressed: _changeStrokeWidth,
        backgroundColor: AppColors.cardColor,
        tooltip: loc.changeStrokeWidth,
        child: Icon(Icons.line_weight, color: AppColors.accentCyan),
      ),
      const SizedBox(height: 8),
      // Clear canvas
      FloatingActionButton(
        heroTag: 'clear',
        mini: true,
        onPressed: () {
          setState(() {
            _loadedImageBytes = null;
            _signatureController.clear();
          });
        },
        backgroundColor: AppColors.warningColor,
        tooltip: loc.clearCanvas,
        child: const Icon(Icons.clear, color: Colors.white),
      ),
      const SizedBox(height: 8),
      // Undo
      FloatingActionButton(
        heroTag: 'undo',
        mini: true,
        onPressed: (_signatureController.points.isEmpty && _loadedImageBytes == null)
            ? null
            : () {
                setState(() {
                  if (_signatureController.points.isNotEmpty) {
                    _signatureController.clear();
                  } else if (_loadedImageBytes != null) {
                    _loadedImageBytes = null;
                  }
                });
              },
        backgroundColor: AppColors.cardColor,
        tooltip: loc.undo,
        child: Icon(Icons.undo, color: AppColors.accentCyan),
      ),
    ];
  }
}
