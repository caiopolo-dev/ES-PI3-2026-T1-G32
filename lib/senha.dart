// código de Rafael Mendes Valente - RA 25002875
import 'package:flutter/material.dart';

class RegisterPasswordPage extends StatefulWidget {
    const RegisterPasswordPage({super.key});

    @override
    State<RegisterPasswordPage> createState() => _RegisterPasswordPageState();
}

class _RegisterPasswordPageState extends State<RegisterPasswordPage> {
    final TextEditingController _passwordController = TextEditingController();
    final TextEditingController _confirmPasswordController = TextEditingController();
    bool _obscurePassword = true;
    bool _obscureConfirm = true;

    @override
    void dispose() {
        _passwordController.dispose();
        _confirmPasswordController.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            backgroundColor: Colors.white,
        body: SafeArea(
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
        children: [
        const SizedBox(height: 60),

        Center(
            child: Row(
                    mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
        Image.asset(
            'assets/MesclaLogoPequena.png',
            width: 50,
        ),
        const SizedBox(width: 8),
        Transform.translate(
            offset: const Offset(0, 3),
            child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
        colors: [
        Color(0xFF000000),
        Color(0xFF013593),
        Color(0xFF080B11),
        ],
        stops: [0.0, 0.5, 1.0],
        ).createShader(bounds),
        child: const Text(
        'MesclaInvest',
        style: TextStyle(
        fontSize: 45,
        color: Colors.white,
        fontFamily: 'JosefinSans',
        ),
        ),
        ),
        ),
        ],
        ),
        ),

        const SizedBox(height: 40),

        const Text(
                'Cadastro passo 4 - 4',
        style: TextStyle(
        fontSize: 22,
        fontFamily: 'JosefinSans',
        fontWeight: FontWeight.bold,
        ),
        ),

        const SizedBox(height: 32),

        // Campo senha
        TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
                    hintText: 'Digite a sua senha',
        hintStyle: const TextStyle(
        fontFamily: 'JosefinSans',
        color: Colors.grey,
        ),
        enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF013593)),
        ),
        suffixIcon: IconButton(
        icon: Icon(
        _obscurePassword ? Icons.visibility_off : Icons.visibility,
        color: Colors.grey,
        ),
        onPressed: () {
        setState(() {
            _obscurePassword = !_obscurePassword;
        });
    },
        ),
        ),
        ),

        const SizedBox(height: 20),

        // Campo confirmar senha
        TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
                    hintText: 'Confirme a sua senha',
        hintStyle: const TextStyle(
        fontFamily: 'JosefinSans',
        color: Colors.grey,
        ),
        enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF013593)),
        ),
        suffixIcon: IconButton(
        icon: Icon(
        _obscureConfirm ? Icons.visibility_off : Icons.visibility,
        color: Colors.grey,
        ),
        onPressed: () {
        setState(() {
            _obscureConfirm = !_obscureConfirm;
        });
    },
        ),
        ),
        ),

        const Spacer(),

        // Botão Continuar
        Center(
            child: Container(
                    width: 320,
        padding: const EdgeInsets.all(1.2),
        decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
        Color.fromARGB(255, 190, 190, 190),
        Color.fromARGB(255, 220, 219, 219),
        Color.fromARGB(255, 190, 190, 190),
        ],
        stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
        blurRadius: 12,
        offset: const Offset(0, 4),
        ),
        ],
        ),
        child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE3E3E3),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
        ),
        elevation: 0,
        ),
        child: const Text(
        'Continuar',
        style: TextStyle(
        color: Colors.black,
        fontFamily: 'JosefinSans',
        fontSize: 20,
        ),
        ),
        ),
        ),
        ),

        const SizedBox(height: 16),

        // Botão Voltar
        Center(
            child: Container(
                    width: 320,
        padding: const EdgeInsets.all(1.2),
        decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
        Color.fromARGB(255, 190, 190, 190),
        Color.fromARGB(255, 220, 219, 219),
        Color.fromARGB(255, 190, 190, 190),
        ],
        stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
        blurRadius: 12,
        offset: const Offset(0, 4),
        ),
        ],
        ),
        child: ElevatedButton(
        onPressed: () {
        Navigator.pop(context);
    },
        style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE3E3E3),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
        ),
        elevation: 0,
        ),
        child: const Text(
        '< Voltar',
        style: TextStyle(
        color: Colors.black,
        fontFamily: 'JosefinSans',
        fontSize: 20,
        ),
        ),
        ),
        ),
        ),
        ],
        ),
        ),
        ),
        );
    }
}
