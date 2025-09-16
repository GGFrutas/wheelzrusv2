import 'package:flutter/material.dart';
import 'package:frontend/theme/colors.dart';
import 'package:frontend/theme/text_styles.dart';
import 'package:frontend/user/confirmation.dart';
import 'package:frontend/user/detailed_details.dart';
import 'package:frontend/user/schedule.dart';

class ProgressRow extends StatelessWidget {
  final int currentStep;
  final String uid;
  final dynamic transaction;

  const ProgressRow({
    super.key,
    required this.currentStep,
    required this.uid,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final stepLabels = [
      'Delivery Log',
      'Schedule',
      'Confirmation',
    ];

    final stepPage = [
      DetailedDetailScreen(uid: uid, transaction: transaction),
      ScheduleScreen(uid: uid, transaction: transaction),
      ConfirmationScreen(uid: uid, transaction: transaction),
    ];

    return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(3 * 2 - 1, (index) {
      // Step indices: 0, 2, 4; Connector indices: 1, 3
      if (index.isEven) {
        int stepIndex = index ~/ 2;
        int displayStep = stepIndex + 1; // For display purposes (1, 2, 3)
        bool isCurrent = displayStep == currentStep;

        Color stepColor = displayStep < currentStep
            ? mainColor // Completed
            : isCurrent
                ? mainColor // Current
                : Colors.grey; // Upcoming

        

        return GestureDetector(
          onTap: () {
            
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => stepPage[stepIndex],
                ),
              );
          },
            child: buildStep(stepLabels[stepIndex], stepColor, isCurrent)
        );
      }else {
        int connectorIndex = (index - 1) ~/ 2 + 1;
        Color connectorColor;
        switch(connectorIndex) {
          case 1:
            connectorColor = currentStep > 1 ? mainColor : Colors.grey;
            break;
          case 2:
            connectorColor = currentStep > 2 ? mainColor : Colors.grey;
            break;
          case 3:
            connectorColor = currentStep > 3 ? mainColor : Colors.grey;
            break;
          default:
            connectorColor = Colors.grey;
        } // Upcoming

        return buildConnector(connectorColor);
      }
    }),
  );
  }
  Widget buildStep(String label, Color color, bool isCurrent) {
    return Column(
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: color,
          child: isCurrent
              ? const CircleAvatar(
                  radius: 7,
                  backgroundColor: Colors.white,
                )
              : null,
        ),
        const SizedBox(height: 5),
        Text(
          label, 
          style: AppTextStyles.caption.copyWith(
            color: color,
          )
        ),
      ],
    );
  }

  /// Connector Line Between Steps
  Widget buildConnector(Color color) {
    return Transform.translate(
      offset: const Offset(0, -10),
      child: 
        Container(
          width: 40,
          height: 4,
          color: color,
        ),
    );
  }
}

