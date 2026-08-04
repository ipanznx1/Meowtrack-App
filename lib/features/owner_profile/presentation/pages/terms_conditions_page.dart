import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/Back.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(Color(0xFF985BEF), BlendMode.srcIn)),
          onPressed: () => context.pop(),
        ),
        title: const Text("Terms and Conditions", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle("Terms and Conditions"),
            _buildLastUpdated("Last updated: June 18, 2026"),
            const SizedBox(height: 20),
            _buildParagraph(
                "Please read these terms and conditions carefully before using Our Service."),
            
            _buildHeader("Interpretation and Definitions"),
            _buildSubHeader("Interpretation"),
            _buildParagraph(
                "The words whose initial letters are capitalized have meanings defined under the following conditions. The following definitions shall have the same meaning regardless of whether they appear in singular or in plural."),
            
            _buildSubHeader("Definitions"),
            _buildParagraph("For the purposes of these Terms and Conditions:"),
            _buildBulletPoint("Application means the software program provided by the Company downloaded by You on any electronic device, named Meowtrack."),
            _buildBulletPoint("Application Store means the digital distribution service operated and developed by Apple Inc. (Apple App Store) or Google Inc. (Google Play Store) in which the Application has been downloaded."),
            _buildBulletPoint("Company (referred to as either 'the Company', 'We', 'Us' or 'Our' in these Terms and Conditions) refers to Meowtrack."),
            _buildBulletPoint("Country refers to: Malaysia"),
            _buildBulletPoint("Device means any device that can access the Service such as a computer, a cell phone or a digital tablet."),
            _buildBulletPoint("Service refers to the Application."),
            _buildBulletPoint("Terms and Conditions (also referred to as 'Terms') means these Terms and Conditions which govern Your access to and use of the Service."),
            _buildBulletPoint("You means the individual accessing or using the Service, or the company, or other legal entity on behalf of which such individual is accessing or using the Service, as applicable."),
            
            _buildHeader("Acknowledgment"),
            _buildParagraph("These are the Terms and Conditions governing the use of this Service and the agreement between You and the Company. These Terms and Conditions set out the rights and obligations of all users regarding the use of the Service."),
            _buildParagraph("Your access to and use of the Service is conditioned on Your acceptance of and compliance with these Terms and Conditions. By accessing or using the Service You agree to be bound by these Terms and Conditions."),
            
            _buildHeader("User Accounts"),
            _buildParagraph("When You create an account with Us, You must provide Us with information that is accurate, complete, and current at all times. Failure to do so constitutes a breach of the Terms, which may result in immediate termination of Your account on Our Service."),
            _buildParagraph("You are responsible for safeguarding the password that You use to access the Service and for any activities or actions under Your password."),
            
            _buildHeader("User Content"),
            _buildParagraph("Our Service allows You to upload, store, and share content, including text (Notes) and images (Gallery). You retain any and all of Your rights to any content You submit, post or display on or through the Service and You are responsible for protecting those rights."),
            
            _buildHeader("Links to Other Websites & Third-Party Services"),
            _buildParagraph("Our Service may contain links or integrate services (such as Google Places API for veterinary directory) that are not owned or controlled by the Company. The Company has no control over, and assumes no responsibility for, the content, privacy policies, or practices of any third-party websites or services."),
            
            _buildHeader("Termination"),
            _buildParagraph("We may terminate or suspend Your access immediately, without prior notice or liability, for any reason whatsoever, including without limitation if You breach these Terms and Conditions. Upon termination, Your right to use the Service will cease immediately."),
            
            _buildHeader("Limitation of Liability"),
            _buildParagraph("To the maximum extent permitted by applicable law, in no event shall the Company or its suppliers be liable for any special, incidental, indirect, or consequential damages whatsoever arising out of or in any way related to the use of or inability to use the Service."),
            
            _buildHeader("Governing Law"),
            _buildParagraph("The laws of Malaysia, excluding its conflicts of law rules, shall govern these Terms and Your use of the Service."),
            
            _buildHeader("Contact Us"),
            _buildParagraph("If you have any questions about these Terms and Conditions, You can contact us:"),
            _buildBulletPoint("By email: 4243003121@student.unisel.edu.my"),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(String text) {
    return Text(text, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black));
  }

  Widget _buildLastUpdated(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 30.0, bottom: 15.0),
      child: Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF985BEF))),
    );
  }

  Widget _buildSubHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
      child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Text(text, style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87)),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, left: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF985BEF))),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87))),
        ],
      ),
    );
  }
}
