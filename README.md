# Operating Systems Assignment 4

## Enhancing xv6 OS

### Specification 1: syscall tracing

The user program corresponding to it (strace) prints all the system calls made by the opearing system with their corresponding arguments and return values.

### Specification 2: Scheduling

- #### FCFS

  Selects the first process based on the time of creation and runs the process that was created the earliest.
- #### PBS

  A non-preemptive scheduling method that schedules the processes based on their dynamic priority.

  #### Set Priority User Program

  Sets the value of the static priority of the process with the passed process id to the passed value.
- #### MLFQ

  A simplified MLFQ scheduler that uses 5 queues and processes to
  move between different priority queues based on their behavior and CPU bursts.

  MLFQ scheduler uses the phenomenon of ageing to prevent starvation.

If a process voluntarily relinquishes control of the CPU(eg. For doing I/O), it
leaves the queuing network, and when the process becomes ready again
after the I/O, it is inserted at the tail of the same queue, from which it is
relinquished earlier.

This is beneficial for a process as its priority remains maintained and it does not have to more the entire ladder up once again to reach the initial position. The tendecy of starvation of such processes decreases to a great extent.

### Performance Comparison

- ### Round Robin:

  - Run-Time: 66
  - Wait-Time: 33
- ### FCFS:

  - Run-Time: 80
  - Wait-Time: 19
- ### PBS:

  - Run-Time: 61
  - Wait-Time: 39
- ### MLFQ:

  - Run-Time: 60
  - Wait-Time: 24

The schedulertest suggests that the FCFS scheduling algorithm provides the best output as compared the rest of the scheduling algorithms since the Run-ime is higher and the Wait-Time is lower.
