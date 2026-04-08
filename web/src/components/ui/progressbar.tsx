"use client";
import React from "react";
import { CheckIcon } from "lucide-react";

interface Step {
  label: string;
  status: "completed" | "current" | "upcoming";
}

interface ProgressStepperProps {
  steps: Step[];
  className?: string;
}

export function ProgressStepper({
  steps,
  className = "",
}: ProgressStepperProps) {
  return (
    <div className={`w-full flex justify-between items-center ${className}`}>
      {steps.map((step, index) => {
        const isLast = index === steps.length - 1;

        const circleClasses =
          step.status === "completed"
            ? "w-6 h-6 rounded-full flex items-center justify-center bg-white border border-white text-black"
            : "w-6 h-6 rounded-full flex items-center justify-center border border-white bg-transparent text-white";

        return (
          <React.Fragment key={index}>
            <div className="flex flex-col items-center">
              <div className={circleClasses}>
                {step.status === "completed" ? (
                  <CheckIcon className="w-4 h-4" />
                ) : (
                  <span className="text-xs font-medium">{index + 1}</span>
                )}
              </div>
              <span className="text-xs mt-1 text-white">{step.label}</span>
            </div>
            {!isLast && <div className="flex-1 mb-6 h-px bg-white mx-2"></div>}
          </React.Fragment>
        );
      })}
    </div>
  );
}
