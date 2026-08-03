import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class InsuranceBenefit {
  final String title;
  final String description;

  const InsuranceBenefit({required this.title, required this.description});
}

class InsurancePartner {
  final String name;
  final String logo;
  final String planName;
  final List<InsuranceBenefit> benefits;
  final String url;

  const InsurancePartner({
    required this.name,
    required this.logo,
    required this.planName,
    required this.benefits,
    required this.url,
  });
}

class InsuranceHubPage extends StatelessWidget {
  const InsuranceHubPage({super.key});

  static const List<InsurancePartner> partners = [
    InsurancePartner(
      name: "Oyen Pet Insurance",
      logo: "assets/images/OYEN INSURANCE.svg",
      planName: "Oyen Cat Medical",
      benefits: [
        InsuranceBenefit(
          title: "Vet fees and surgical fees",
          description:
              "Meliputi konsultasi, pembedahan, dan kos berkaitan kemalangan (konsultasi rutin tidak dilindungi).",
        ),
        InsuranceBenefit(
          title: "Diagnosis and blood test",
          description:
              "Ujian makmal yang disertakan dengan rawatan (pemeriksaan rutin tidak dilindungi).",
        ),
        InsuranceBenefit(
          title: "Clinic overnight stay",
          description: "Perlindungan untuk penginapan di klinik jika kucing sakit.",
        ),
        InsuranceBenefit(
          title: "Prescribed medication",
          description:
              "Ubat-ubatan apabila kucing sakit (supplemen rutin tidak dilindungi).",
        ),
        InsuranceBenefit(
          title: "X-Ray/Ultrasound",
          description:
              "Ujian pengimejan yang disertakan dengan rawatan (pemeriksaan rutin tidak dilindungi).",
        ),
        InsuranceBenefit(
          title: "Follow up treatment",
          description: "Kos rawatan susulan di klinik veterinar sehingga 60 hari.",
        ),
        InsuranceBenefit(
          title: "Farewell cost",
          description:
              "Kos pengebumian atau kremasi (untuk pelan Cat Plus dan Champion sahaja).",
        ),
        InsuranceBenefit(
          title: "Injury or damage by your cat",
          description:
              "Perlindungan kos kerosakan atau kecederaan kepada pihak ketiga (untuk pelan Cat Plus dan Champion sahaja).",
        ),
      ],
      url: "https://www.oyen.my/cat-insurance",
    ),
    InsurancePartner(
      name: "MSIG Insurance",
      logo: "assets/images/MSIG.svg",
      planName: "Pet Safe Plan",
      benefits: [
        InsuranceBenefit(
          title: "Veterinary fees",
          description: "Rawatan klinik & pembedahan",
        ),
        InsuranceBenefit(
          title: "Death coverage",
          description: "Pampasan kecederaan atau penyakit",
        ),
        InsuranceBenefit(
          title: "Burial/Cremation",
          description: "Kos pengurusan pengebumian",
        ),
        InsuranceBenefit(
          title: "Search & Reward",
          description: "Kos mencari kucing hilang",
        ),
        InsuranceBenefit(
          title: "Boarding fees",
          description: "Kos penginapan di cattery",
        ),
      ],
      url: "https://www.msig.com.my/products/personal/lifestyle/pet/#plans",
    ),
  ];

  Future<void> _launchPartnerUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/Back.svg',
            width: 24,
            colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn),
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          "MeowProtect Hub",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Official Partners",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              "Verified pet insurance providers in Malaysia.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 25),
            ...partners.map(_buildInsuranceCard),
          ],
        ),
      ),
    );
  }

  Widget _buildInsuranceCard(InsurancePartner p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SvgPicture.asset(
                  p.logo,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.shield_outlined, color: Color(0xFF985BEF)),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.planName,
                      style: const TextStyle(
                        color: Color(0xFF985BEF),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE0E0E8)),
          const SizedBox(height: 8),
          Column(
            children: p.benefits.map((b) => _buildBenefitTile(b)).toList(),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _launchPartnerUrl(p.url),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF985BEF),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 0,
            ),
            child: const Text(
              "Learn More",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitTile(InsuranceBenefit benefit) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: const Icon(Icons.check_circle, color: Colors.green, size: 20),
      title: Text(
        benefit.title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          benefit.description,
          style: const TextStyle(fontSize: 12, height: 1.35, color: Colors.black54),
        ),
      ),
      isThreeLine: true,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}
